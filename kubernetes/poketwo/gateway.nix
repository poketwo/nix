{ ... }:

{
  namespaces.poketwo.resources = {
    v1.Service.gateway.spec = {
      selector.app = "gateway";
      ports = [{ port = 80; targetPort = "bridge"; }];
      # Readiness only passes with every shard on Discord, so a flapping shard would stop new bot
      # pods from attaching to the bridge, which serves the shards that are up.
      publishNotReadyAddresses = true;
    };

    "apps/v1".StatefulSet.gateway.spec = {
      replicas = 1;
      selector.matchLabels.app = "gateway";
      serviceName = "gateway";
      template = {
        metadata.labels.app = "gateway";
        spec = {
          containers.gateway = {
            image = "ghcr.io/poketwo/poketwo-rs:production";
            imagePullPolicy = "Always";
            ports = [
              { name = "metrics"; containerPort = 9000; }
              { name = "bridge"; containerPort = 7878; }
            ];
            livenessProbe = {
              httpGet = { path = "/livez"; port = "metrics"; };
              periodSeconds = 30;
              timeoutSeconds = 5;
            };
            readinessProbe = {
              httpGet = { path = "/readyz"; port = "metrics"; };
              periodSeconds = 2;
              # A shard that resumes counts as down for ~1.2s, and with 1600 shards one is
              # resuming ~23% of the time and three failed probes in a row happen every few minutes.
              failureThreshold = 15;
            };
            resources = {
              requests = { memory = "4Gi"; cpu = "500m"; };
              limits = { memory = "32Gi"; cpu = "8000m"; };
            };
            env = {
              BOT_TOKEN.valueFrom.secretKeyRef = { name = "poketwo"; key = "BOT_TOKEN"; };
              REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-cache"; key = "redis-password"; };
              REDIS_URL.value = "redis://:$(REDIS_PASSWORD)@valkey-haproxy";
              SHARDS_TOTAL.value = "1600";
              SHARDS_PER_REPLICA.value = "1600";
              WORKERS.value = "1";
              METRICS_ADDR.value = "[::]:9000";
              BRIDGE_ADDR.value = "[::]:7878";
              BRIDGE_REPLAY_CONCURRENCY.value = "32";
              ACTIVITY.value = "@Pokétwo help";
              LOG_FORMAT.value = "json";
              RUST_LOG.value = "info";
            };
          };
          imagePullSecrets.ghcr-auth = { };
          terminationGracePeriodSeconds = 30;
        };
      };
    };
  };
}
