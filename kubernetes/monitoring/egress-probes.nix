{ ... }:

let
  # Every worker carries its pods' IPv4 traffic through its own Jool, so the
  # probes run per node from the pod network, like the gateway and bot pods.
  # Pairing NAT64 targets with native-IPv6 ones to the same networks tells a
  # Jool/upstream-IPv4 outage apart from the node losing the internet.
  targets = [
    { name = "discord-gateway"; path = "nat64"; target = "gateway.discord.gg:443"; }
    { name = "cloudflare"; path = "nat64"; target = "[64:ff9b::101:101]:443"; } # 1.1.1.1
    { name = "cloudflare"; path = "ipv6"; target = "[2606:4700:4700::1111]:443"; }
    { name = "google"; path = "ipv6"; target = "[2001:4860:4860::8888]:443"; }
  ];
in
{
  namespaces.prometheus.resources = {
    v1.ConfigMap.egress-probes.data."blackbox.yml" = builtins.toJSON {
      modules.tcp_connect = {
        prober = "tcp";
        timeout = "5s";
        tcp = {
          preferred_ip_protocol = "ip6";
          ip_protocol_fallback = false;
        };
      };
    };

    "apps/v1".DaemonSet.egress-probes.spec = {
      selector.matchLabels.app = "egress-probes";

      template = {
        metadata.labels.app = "egress-probes";

        spec = {
          containers.blackbox-exporter = {
            image = "quay.io/prometheus/blackbox-exporter:v0.29.1";
            args = [ "--config.file=/config/blackbox.yml" ];
            ports = [{ name = "probe"; containerPort = 9115; }];

            resources = {
              requests = { cpu = "10m"; memory = "32Mi"; };
              limits.memory = "64Mi";
            };

            securityContext = {
              runAsNonRoot = true;
              runAsUser = 65534;
              readOnlyRootFilesystem = true;
              allowPrivilegeEscalation = false;
              capabilities.drop = [ "ALL" ];
            };

            volumeMounts = [{
              name = "config";
              mountPath = "/config";
              readOnly = true;
            }];
          };

          volumes = [{
            name = "config";
            configMap.name = "egress-probes";
          }];
        };
      };
    };

    # probe_success{probe, path, node}
    "monitoring.coreos.com/v1".PodMonitor.egress-probes.spec = {
      selector.matchLabels.app = "egress-probes";

      podMetricsEndpoints = map (t: {
        port = "probe";
        path = "/probe";
        interval = "15s";
        scrapeTimeout = "10s";
        params = {
          module = [ "tcp_connect" ];
          target = [ t.target ];
        };
        relabelings = [
          { targetLabel = "probe"; replacement = t.name; }
          { targetLabel = "path"; replacement = t.path; }
          { targetLabel = "target"; replacement = t.target; }
          { sourceLabels = [ "__meta_kubernetes_pod_node_name" ]; targetLabel = "node"; }
        ];
      }) targets;
    };
  };
}
