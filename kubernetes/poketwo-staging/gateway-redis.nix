{ transpire, ... }:

{
  namespaces.poketwo-staging = {
    helmReleases.gateway-redis = {
      chart = transpire.fetchFromHelm {
        repo = "https://valkey.io/valkey-helm/";
        name = "valkey";
        version = "0.12.0";
        sha256 = "";
      };

      values = {
        auth = {
          enabled = true;
          usersExistingSecret = "gateway-redis";
          aclUsers.default = {
            permissions = "~* &* +@all";
            passwordKey = "redis-password";
          };
        };
        extraConfig = ''
          save 60 1
          appendonly no
          maxmemory-policy noeviction
        '';
        persistence = {
          enabled = true;
          size = "2Gi";
          storageClass = "rbd-nvme";
        };
        resources = {
          requests = { memory = "512Mi"; };
          limits = { memory = "512Mi"; cpu = "50m"; };
        };
        terminationGracePeriodSeconds = 120;
        metrics.enabled = true;
      };
    };

    resources.v1.Secret.gateway-redis.stringData = {
      redis-password = "";
    };
  };
}
