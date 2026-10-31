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
          save ""
          appendonly no
          maxmemory-policy noeviction
        '';
        resources = {
          requests = { memory = "48Gi"; };
          limits = { memory = "128Gi"; cpu = "2000m"; };
        };
        deploymentStrategy = "Recreate";
        metrics.enabled = true;
      };
    };

    # Replacement for the single Valkey above: 3 pods with Sentinel and HAProxy in
    # front, so a drain fails over to a replica instead of emptying the cache.
    helmReleases.gateway-cache-ha = {
      chart = transpire.fetchFromHelm {
        repo = "https://dandydeveloper.github.io/charts";
        name = "redis-ha";
        version = "4.39.0";
        sha256 = "RXbF+K3iQRizyUsVQDpn/iXdNX7inaJ7N3N4OuY5owM=";
      };

      values = {
        fullnameOverride = "gateway-cache-ha";
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
            appendonly = "no";
            maxmemory-policy = "noeviction";
            min-replicas-to-write = 0;
            repl-backlog-size = "1gb";
            repl-diskless-load = "on-empty-db";
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
          podDisruptionBudget.maxUnavailable = 1;
        };
        exporter.enabled = true;
      };
    };

    resources.v1.Secret.gateway-cache.stringData = {
      redis-password = "";
    };
  };
}
