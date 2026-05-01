{ ... }:

{
  namespaces.poketwo-staging-private.resources = {
    v1.Service.poketwo.spec = {
      selector.app = "poketwo";
      clusterIP = "None";
    };

    "apps/v1".StatefulSet.poketwo.spec = {
      replicas = 0;
      selector.matchLabels.app = "poketwo";
      serviceName = "poketwo";
      template = {
        metadata.labels.app = "poketwo";
        spec = {
          containers.poketwo = {
            image = "ghcr.io/poketwo/poketwo:feature-spring_2026";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; };
              requests = { memory = "2Gi"; cpu = "100m"; };
            };
            envFrom = [{ secretRef.name = "poketwo"; }];
            env = {
              DATABASE_URI.valueFrom.secretKeyRef = { name = "mongodb-admin-poketwo"; key = "connectionString.standard"; };
              DATABASE_NAME.value = "pokemon_dev";
              REDIS_URI.value = "redis://redis-master";
              REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };
              SERVER_URL.value = "http://image-server.poketwo";
              EXT_SERVER_URL.value = "https://server.poketwo.io";
              IMGEN_URL.value = "http://imgen-rust.poketwo";
              API_GATEWAY.value = "ws://gateway-proxy";
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };
  };
}
