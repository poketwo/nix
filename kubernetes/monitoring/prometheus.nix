{ lib, transpire, ... }:

{
  namespaces.prometheus = {
    helmReleases = {
      prometheus-operator-crds = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "prometheus-operator-crds";
          version = "12.0.0";
          sha256 = "7fdZmV1imCea3iNugBEUpx24BxB+zTuq1jdo+JNyZl0=";
        };
      };

      prometheus-node-exporter = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "prometheus-node-exporter";
          version = "4.36.0";
          sha256 = "n63qKrSv7F+TDI2Sq8YjVu527veZl2asDyFREJd0Mak=";
        };

        # On the pod network so Alloy can reach it like zfs-exporter: on the
        # host network, port 9100 is firewalled on the hosts. /proc and /sys
        # are still the host's (mounted at /host), so disk, ZFS, CPU, memory
        # and filesystem metrics are node-wide. Network collectors would only
        # see the pod's own netns, so they're off.
        values = {
          hostNetwork = false;
          extraArgs = [
            "--no-collector.arp"
            "--no-collector.conntrack"
            "--no-collector.netdev"
            "--no-collector.netstat"
            "--no-collector.sockstat"
          ];
        };
      };

      kube-state-metrics = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "kube-state-metrics";
          version = "5.20.0";
          sha256 = "7wPQe1NRQIxADnks/ZnlFk+HAWfVqNlOaOQN93whL/8=";
        };
      };
    };

    # The chart listens on [$(HOST_IP)]:9100 with HOST_IP=0.0.0.0, which is
    # IPv4-only; pods here only have an IPv6 address.
    resources."apps/v1".DaemonSet.prometheus-node-exporter.spec.template.spec.containers.node-exporter.env.HOST_IP.value = lib.mkForce "::";
  };
}
