{ transpire, ... }:

{
  namespaces.poketwo = {
    # Shared Valkey for the gateway and the bot: 3 pods with Sentinel and HAProxy in
    # front, so a drain fails over to a replica instead of emptying it. No persistence.
    helmReleases.valkey = {
      chart = transpire.fetchFromHelm {
        repo = "https://dandydeveloper.github.io/charts";
        name = "redis-ha";
        version = "4.39.0";
        sha256 = "RXbF+K3iQRizyUsVQDpn/iXdNX7inaJ7N3N4OuY5owM=";
      };

      values = {
        fullnameOverride = "valkey";
        image = {
          repository = "docker.io/valkey/valkey";
          tag = "9.1.2";
        };
        auth = true;
        existingSecret = "gateway-cache";
        authKey = "redis-password";
        redis = {
          config = {
            save = ''""'';
            maxmemory-policy = "noeviction";
            min-replicas-to-write = 0;
            # the 10mb default is ~3 s of writes; past that a replica reconnect is a full 46 GB sync
            repl-backlog-size = "1gb";
            client-output-buffer-limit = "replica 16gb 16gb 0";
          };
          resources = {
            requests = { memory = "48Gi"; };
            limits = { memory = "128Gi"; cpu = "2000m"; };
          };
        };
        persistentVolume.enabled = false;
        podDisruptionBudget.maxUnavailable = 1;
        haproxy = {
          enabled = true;
          # the default of 1 failed check would cut the gateway off on a fork stall
          checkFall = 3;
        };
      };
    };

    resources.v1.Secret.gateway-cache.stringData = {
      redis-password = "";
    };
  };
}
