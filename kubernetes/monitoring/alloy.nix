{ lib, transpire, ... }:

let
  # Probes run by the blackbox exporter on each worker host (network.nix), on
  # the host network: native IPv4 and IPv6 side by side, plus NAT64 through
  # that host's own Jool (the host routes 64:ff9b::/96 into it). 8.8.8.8 tells
  # a provider IPv4 fault apart from a Cloudflare/Discord one, and the router
  # tells the LAN apart from upstream. The host resolver returns A records, so
  # gateway.discord.gg over tcp4 is plain IPv4.
  hostProbes = [
    { probe = "discord-gateway"; path = "ipv4"; module = "tcp4"; target = "gateway.discord.gg:443"; }
    { probe = "discord-gateway"; path = "nat64"; module = "tcp6"; target = "[64:ff9b::a29f:85ea]:443"; } # 162.159.133.234
    { probe = "cloudflare"; path = "ipv4"; module = "tcp4"; target = "1.1.1.1:443"; }
    { probe = "cloudflare"; path = "nat64"; module = "tcp6"; target = "[64:ff9b::101:101]:443"; }
    { probe = "cloudflare"; path = "ipv6"; module = "tcp6"; target = "[2606:4700:4700::1111]:443"; }
    { probe = "google"; path = "ipv4"; module = "tcp4"; target = "8.8.8.8:443"; }
    { probe = "google"; path = "nat64"; module = "tcp6"; target = "[64:ff9b::808:808]:443"; }
    { probe = "google"; path = "ipv6"; module = "tcp6"; target = "[2001:4860:4860::8888]:443"; }
    { probe = "router"; path = "ipv4"; module = "icmp4"; target = "23.135.200.1"; }
    { probe = "router"; path = "ipv6"; module = "icmp6"; target = "2606:c2c0::1"; }
  ];

  hostProbeConfig = ''

    // Workers only: the blackbox exporter runs on hosts in the workers' prefix.
    discovery.relabel "host_probe_nodes" {
      targets = discovery.relabel.nodes.output
      rule {
        source_labels = ["__meta_kubernetes_node_address_InternalIP"]
        regex         = "(2606:c2c0:5:.*)"
        action        = "keep"
      }
      rule {
        source_labels = ["__meta_kubernetes_node_address_InternalIP"]
        target_label  = "__address__"
        replacement   = "[$1]:9115"
      }
    }
  '' + lib.concatMapStrings (p:
    let id = lib.replaceStrings [ "-" ] [ "_" ] "${p.probe}_${p.path}"; in ''

      discovery.relabel "host_probe_${id}" {
        targets = discovery.relabel.host_probe_nodes.output
        rule {
          target_label = "probe"
          replacement  = "${p.probe}"
        }
        rule {
          target_label = "path"
          replacement  = "${p.path}"
        }
      }

      prometheus.scrape "host_probe_${id}" {
        targets         = discovery.relabel.host_probe_${id}.output
        job_name        = "host-probe"
        metrics_path    = "/probe"
        params          = { "module" = ["${p.module}"], "target" = ["${p.target}"] }
        scrape_interval = "15s"
        forward_to      = [prometheus.remote_write.default.receiver]
        clustering { enabled = true }
      }
    '') hostProbes;
in
{
  namespaces.alloy = {
    helmReleases.alloy = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "alloy";
        version = "1.15.0";
        sha256 = "efDrZJdDGVGHGkuC5KOE74IHz+/GrUJJU8RZwpY8lgE=";
      };

      values = {
        controller = {
          type = "statefulset";
          replicas = 3;
        };

        alloy = {
          clustering.enabled = true;
          configMap.content = builtins.readFile ./alloy/config.alloy + hostProbeConfig;
        };
      };

      includeCRDs = true;
    };
  };
}
