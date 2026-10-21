{ ... }:

{
  namespaces.poketwo-rs.resources = {
    "apps/v1".Deployment.cache-live.spec = {
      replicas = 1;
      selector.matchLabels.app = "cache-live";
      template = {
        metadata.labels.app = "cache-live";
        spec = {
          containers.cache-live = {
            image = "ghcr.io/poketwo/poketwo-rs:devin-1792561467-rs-image";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "256Mi"; };
              requests = { memory = "128Mi"; cpu = "50m"; };
            };
            env = {
              BOT_TOKEN.valueFrom.secretKeyRef = { name = "poketwo"; key = "TOKEN"; };
              REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };
              REDIS_URL.value = "redis://:$(REDIS_PASSWORD)@redis-master";
              LOG_FORMAT.value = "json";
              RUST_LOG.value = "info";
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    v1.Secret.poketwo.stringData = {
      TOKEN = "";
    };
  };
}
