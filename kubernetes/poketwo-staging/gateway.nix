{ ... }:

{
  namespaces.poketwo-staging.resources."apps/v1".StatefulSet.gateway.spec = {
    replicas = 1;
    selector.matchLabels.app = "gateway";
    serviceName = "gateway";
    template = {
      metadata.labels.app = "gateway";
      spec = {
        containers.gateway = {
          image = "ghcr.io/poketwo/poketwo-rs:production";
          imagePullPolicy = "Always";
          ports = [{ name = "metrics"; containerPort = 9000; }];
          resources = {
            requests = { memory = "128Mi"; cpu = "50m"; };
            limits = { memory = "256Mi"; cpu = "200m"; };
          };
          env = {
            BOT_TOKEN.valueFrom.secretKeyRef = { name = "poketwo"; key = "TOKEN"; };
            REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-cache"; key = "redis-password"; };
            REDIS_URL.value = "redis://:$(REDIS_PASSWORD)@gateway-cache-valkey";
            SHARDS_TOTAL.value = "1";
            SHARDS_PER_REPLICA.value = "1";
            WORKERS.value = "1";
            METRICS_ADDR.value = "[::]:9000";
            LOG_FORMAT.value = "json";
            RUST_LOG.value = "info";
          };
        };
        imagePullSecrets = [{ name = "ghcr-auth"; }];
        terminationGracePeriodSeconds = 30;
      };
    };
  };
}
