{ transpire, ... }:

{
  namespaces.poketwo.helmReleases.gateway-redis = {
    chart = transpire.fetchFromHelm {
      repo = "https://charts.bitnami.com/bitnami";
      name = "redis";
      version = "19.6.1";
      sha256 = "z7M/oHv2x9LVaMaPXk5KfYYqZs7m7+PmLxnKjL0Thxs=";
    };

    values = {
      global.imageRegistry = "docker.io";
      global.security.allowInsecureImages = true;
      image.repository = "bitnamilegacy/redis";
      sentinel.image.repository = "bitnamilegacy/redis-sentinel";
      architecture = "standalone";
      usePassword = true;
      commonConfiguration = ''
        appendonly no
        save ""
      '';
      master = {
        persistence.enabled = false;
        resources = {
          requests = { memory = "20Gi"; };
          limits = { memory = "20Gi"; cpu = "1000m"; };
        };
      };
      metrics = {
        enabled = true;
        image.repository = "bitnamilegacy/redis-exporter";
      };
      networkPolicy.enabled = false;
      volumePermissions.image.repository = "bitnamilegacy/os-shell";
      sysctl.image.repository = "bitnamilegacy/os-shell";
      kubectl.image.repository = "bitnamilegacy/kubectl";
    };
  };
}
