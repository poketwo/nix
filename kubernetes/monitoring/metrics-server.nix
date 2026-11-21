{ transpire, ... }:

{
  namespaces.metrics-server = {
    helmReleases = {
      metrics-server = {
        chart = transpire.fetchFromHelm {
          repo = "https://kubernetes-sigs.github.io/metrics-server/";
          name = "metrics-server";
          version = "3.14.0";
          sha256 = "6MRrUlscZAn2c7SK9u+GtwgpWLAp5Lph49djpJwahdg=";
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
