{ transpire, ... }:

{
  namespaces.metrics-server = {
    helmReleases = {
      metrics-server = {
        chart = transpire.fetchFromHelm {
          repo = "https://kubernetes-sigs.github.io/metrics-server/";
          name = "metrics-server";
          version = "3.12.1";
          sha256 = "I4A5zSvkif0E1Y7N9LlqHGSDt0PTGHeLB5nMMX2Ebr0=";
        };

        # values = {
        #   defaultArgs = [
        #     "--cert-dir=/tmp"
        #     "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
        #     "--kubelet-use-node-status-port"
        #     "--metric-resolution=15s"
        #     "--kubelet-insecure-tls"
        #   ];
        # };
      };
    };
  };
}
