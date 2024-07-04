{ transpire, ... }:

{
  namespaces.alloy = {
    helmReleases.alloy = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "alloy";
        version = "0.3.2";
        sha256 = "/H288hrHvRSWQz/aHacsPtBs0jVOYlpIC9RC3+nm1Ow=";
      };

      values = {
        controller = {
          type = "statefulset";
          replicas = 3;
        };

        alloy = {
          clustering.enabled = true;
          configMap.content = builtins.readFile ./alloy/config.alloy;
        };
      };

      includeCRDs = true;
    };
  };
}
