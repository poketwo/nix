{ transpire, ... }:

{
  namespaces.poketwo-staging-private.helmReleases.redis = {
    chart = transpire.fetchFromHelm {
      repo = "https://charts.bitnami.com/bitnami";
      name = "redis";
      version = "19.6.1";
      sha256 = "z7M/oHv2x9LVaMaPXk5KfYYqZs7m7+PmLxnKjL0Thxs=";
    };

    values = {
      global.imageRegistry = "docker.io/bitnamilegacy";
      architecture = "standalone";
      usePassword = true;
      master = {
        persistence.size = "2Gi";
        resources = {
          requests = { memory = "1Gi"; };
          limits = { memory = "1Gi"; cpu = "20m"; };
        };
      };
      metrics.enabled = true;
      networkPolicy.enabled = false;
    };
  };
}
