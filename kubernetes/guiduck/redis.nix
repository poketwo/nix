{ transpire, ... }:

{
  namespaces.guiduck = {
    helmReleases.redis = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "redis";
        version = "21.1.4";
        sha256 = "sha256-8ck20hGFWdd9/zrnAxKvK2Z5t28+KOKR6UyB/mJQDgw=";
      };

      values = {
        global.imageRegistry = "docker.io";
        global.security.allowInsecureImages = true;
        image.repository = "bitnamilegacy/redis";
        sentinel.image.repository = "bitnamilegacy/redis-sentinel";
        architecture = "standalone";
        usePassword = true;
        master = {
          persistence.size = "4Gi";
          resources = {
            requests = { memory = "1Gi"; };
            limits = { memory = "1Gi"; cpu = "50m"; };
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
  };
}
