{ transpire, ... }:

{
  namespaces.poketwo = {
    helmReleases.gateway-cache = {
      chart = transpire.fetchFromHelm {
        repo = "https://valkey.io/valkey-helm/";
        name = "valkey";
        version = "0.12.0";
        sha256 = "9++qWjvvYyVnp9KfqLYd/bLdyqJG1v5DCFD+acWUBws=";
      };

      values = {
        auth = {
          enabled = true;
          usersExistingSecret = "gateway-cache";
          aclUsers.default = {
            permissions = "~* &* +@all";
            passwordKey = "redis-password";
          };
        };
        valkeyConfig = ''
          save 60 1
          appendonly no
          maxmemory-policy noeviction
        '';
        dataStorage = {
          enabled = true;
          requestedSize = "40Gi";
          className = "rbd-nvme";
        };
        resources = {
          requests = { memory = "20Gi"; };
          limits = { memory = "20Gi"; cpu = "1000m"; };
        };
        deploymentStrategy = "Recreate";
        metrics.enabled = true;
      };
    };

    resources.v1.Secret.gateway-cache.stringData = {
      redis-password = "";
    };
  };
}
