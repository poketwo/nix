{ transpire, ... }:

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

      kube-state-metrics = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "kube-state-metrics";
          version = "5.20.0";
          sha256 = "7wPQe1NRQIxADnks/ZnlFk+HAWfVqNlOaOQN93whL/8=";
        };
      };
    };
  };
}
