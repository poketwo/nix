{ transpire, ... }:

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
          configMap.content = builtins.readFile ./alloy/config.alloy;
        };
      };

      includeCRDs = true;
    };
  };
}
