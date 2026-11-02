{ transpire, ... }:

{
  namespaces.prometheus = {
    helmReleases = {
      prometheus-operator-crds = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "prometheus-operator-crds";
          version = "32.0.2";
          sha256 = "hFk7NME6TmXaJClR4m1PFLzDVxTl/vSJIRxcoOZ0VJs=";
        };
      };

      prometheus-node-exporter = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "prometheus-node-exporter";
          version = "4.36.0";
          sha256 = "n63qKrSv7F+TDI2Sq8YjVu527veZl2asDyFREJd0Mak=";
        };
      };

      kube-state-metrics = {
        chart = transpire.fetchFromHelm {
          repo = "https://prometheus-community.github.io/helm-charts";
          name = "kube-state-metrics";
          version = "8.8.0";
          sha256 = "38Xj9EJtTDwtvXNqDJLkFsg5+YkGjiT45KYVhh/MHpw=";
        };
      };
    };
  };
}
