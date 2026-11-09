{ lib, transpire, ... }:

let
  chart = transpire.fetchFromHelm {
    repo = "https://grafana.github.io/helm-charts";
    name = "alloy";
    version = "1.15.0";
    sha256 = "efDrZJdDGVGHGkuC5KOE74IHz+/GrUJJU8RZwpY8lgE=";
  };

  # Outbound reachability probes (blackbox exporter built into Alloy), so a
  # "v4 to Cloudflare died on every worker" outage shows up as
  # probe_success{job="integrations/blackbox/<host|pod>-<target>", node}.
  blackboxModules = {
    icmp4 = { prober = "icmp"; timeout = "5s"; icmp.preferred_ip_protocol = "ip4"; };
    icmp6 = { prober = "icmp"; timeout = "5s"; icmp.preferred_ip_protocol = "ip6"; };
    http4 = { prober = "http"; timeout = "5s"; http = { preferred_ip_protocol = "ip4"; ip_protocol_fallback = false; }; };
    http6 = { prober = "http"; timeout = "5s"; http = { preferred_ip_protocol = "ip6"; ip_protocol_fallback = false; }; };
    tcp6 = { prober = "tcp"; timeout = "5s"; tcp = { preferred_ip_protocol = "ip6"; ip_protocol_fallback = false; }; };
  };

  cloudflare = "162.159.133.234"; # gateway.discord.gg anycast
  google = "8.8.8.8";

  # From the host: native v4 and v6 side by side, Cloudflare vs others, and
  # the workers' router (from the Linode control planes this is a cross-site
  # probe, not their own gateway). The host routes 64:ff9b::/96 into its own
  # Jool, so the nat64 targets show per node whether that host's Jool and the
  # v4 path behind it work. The pod runs with cluster DNS, which hides A
  # records (and synthesizes 64:ff9b:: AAAA), so v4 targets must be IP literals.
  hostTargets = {
    cloudflare-icmp4 = { address = cloudflare; module = "icmp4"; };
    google-icmp4 = { address = google; module = "icmp4"; };
    worker-router-icmp4 = { address = "23.135.200.1"; module = "icmp4"; };
    cloudflare-icmp6 = { address = "2606:4700:4700::1111"; module = "icmp6"; };
    google-icmp6 = { address = "2001:4860:4860::8888"; module = "icmp6"; };
    worker-router-icmp6 = { address = "2606:c2c0::1"; module = "icmp6"; };
    cloudflare-http4 = { address = "https://1.1.1.1/cdn-cgi/trace"; module = "http4"; };
    cloudflare-http6 = { address = "https://www.cloudflare.com/cdn-cgi/trace"; module = "http6"; };
    google-http6 = { address = "https://www.google.com/generate_204"; module = "http6"; };
    cloudflare-nat64-icmp = { address = "64:ff9b::${cloudflare}"; module = "icmp6"; };
    google-nat64-icmp = { address = "64:ff9b::${google}"; module = "icmp6"; };
    discord-gateway-nat64-tcp = { address = "gateway.discord.gg:443"; module = "tcp6"; };
    google-nat64-tcp = { address = "[64:ff9b::${google}]:443"; module = "tcp6"; };
  };

  # From the pod network: v4-only hosts resolve through DNS64 and go via Jool;
  # the 64:ff9b:: literals exercise Jool without DNS.
  podTargets = {
    cloudflare-nat64-icmp = { address = "64:ff9b::${cloudflare}"; module = "icmp6"; };
    google-nat64-icmp = { address = "64:ff9b::${google}"; module = "icmp6"; };
    cloudflare-icmp6 = { address = "2606:4700:4700::1111"; module = "icmp6"; };
    discord-nat64-http = { address = "https://discord.com/api/v10/gateway"; module = "http6"; };
    github-nat64-http = { address = "https://github.com/"; module = "http6"; };
    cloudflare-http6 = { address = "https://www.cloudflare.com/cdn-cgi/trace"; module = "http6"; };
  };

  blackboxConfig = name: targets: clustering: ''
    prometheus.exporter.blackbox "${name}" {
      config = ${builtins.toJSON (builtins.toJSON { modules = blackboxModules; })}
    ${lib.concatStrings (lib.mapAttrsToList (tname: t: ''
        target {
          name    = "${name}-${tname}"
          address = "${t.address}"
          module  = "${t.module}"
        }
    '') targets)}}

    prometheus.scrape "blackbox_${name}" {
      targets         = prometheus.exporter.blackbox.${name}.targets
      scrape_interval = "15s"
      forward_to      = [prometheus.remote_write.default.receiver]
      clustering { enabled = ${lib.boolToString clustering} }
    }
  '';

  hostMounts = {
    journal = "/var/log/journal";
  };

  # Survives restarts so loki.source.journal keeps its cursor.
  hostStateDir = "/var/lib/alloy-host";
in

{
  namespaces.alloy = {
    helmReleases = {
      # Cluster-wide collector: pod metrics/logs, k8s events, *Monitor CRs.
      alloy = {
        inherit chart;

        values = {
          controller = {
            type = "statefulset";
            replicas = 3;
          };

          alloy = {
            clustering.enabled = true;
            securityContext.capabilities.add = [ "NET_RAW" ];
            configMap.content = builtins.readFile ./alloy/config.alloy + "\n" + blackboxConfig "pod" podTargets true;
          };
        };

        includeCRDs = true;
      };

      # One per node on the host network: host journal and per-node probes
      # (native v4/v6 and via that host's Jool). Pushes directly, so the host firewall can stay closed.
      alloy-host = {
        inherit chart;

        values = {
          controller = {
            type = "daemonset";
            hostNetwork = true;
            dnsPolicy = "ClusterFirstWithHostNet";
            tolerations = [{ key = "node-role.kubernetes.io/control-plane"; effect = "NoSchedule"; }];
            volumes.extra = lib.mapAttrsToList (name: path: { inherit name; hostPath = { inherit path; }; }) hostMounts
              ++ [{ name = "state"; hostPath = { path = hostStateDir; type = "DirectoryOrCreate"; }; }];
          };

          alloy = {
            # Keep the unauthenticated HTTP API off the node's addresses. This
            # also drops the chart's readiness probe, which would hit the node IP.
            listenAddr = "127.0.0.1";
            enableHttpServerPort = false;
            livenessProbe.httpGet = { host = "127.0.0.1"; path = "/-/healthy"; port = 12345; };
            securityContext.capabilities.add = [ "NET_RAW" ];
            extraEnv = [{ name = "NODE_NAME"; valueFrom.fieldRef.fieldPath = "spec.nodeName"; }];
            storagePath = hostStateDir;
            mounts.extra = lib.mapAttrsToList (name: _: { inherit name; mountPath = "/host/${name}"; readOnly = true; }) hostMounts
              ++ [{ name = "state"; mountPath = hostStateDir; }];
            configMap.content = builtins.readFile ./alloy/host.alloy + "\n" + blackboxConfig "host" hostTargets false;
          };

          rbac.create = false;
        };
      };
    };
  };
}
