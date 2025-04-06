{ transpire, ... }:

{
  namespaces.poketwo = {
    helmReleases.redis = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "redis";
        version = "19.6.1";
        sha256 = "z7M/oHv2x9LVaMaPXk5KfYYqZs7m7+PmLxnKjL0Thxs=";
      };

      values = {
        architecture = "standalone";
        usePassword = true;
        master = {
          persistence.size = "64Gi";
          resources = {
            requests = { memory = "30Gi"; };
            limits = { memory = "30Gi"; cpu = "1000m"; };
          };
        };
        metrics.enabled = true;
        networkPolicy.enabled = false;
      };
    };
  };
}
