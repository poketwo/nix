{ ... }:

{
  namespaces.poketwo-staging.resources = {
    v1.Service.poketwo.spec = {
      selector.app = "poketwo";
      clusterIP = "None";
    };

    "apps/v1".StatefulSet.poketwo.spec = {
      replicas = 1;
      selector.matchLabels.app = "poketwo";
      serviceName = "poketwo";
      template = {
        metadata.labels.app = "poketwo";
        spec = {
          containers = [{
            name = "poketwo";
            image = "ghcr.io/poketwo/poketwo:production";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; };
              requests = { memory = "2Gi"; cpu = "100m"; };
            };
            envFrom = [{ secretRef.name = "poketwo"; }];
            env = [
              { name = "DATABASE_URI"; valueFrom.secretKeyRef = { name = "mongodb-admin-poketwo"; key = "connectionString.standard"; }; }
              { name = "DATABASE_NAME"; value = "pokemon_dev"; }
              { name = "REDIS_URI"; value = "redis://redis-master"; }
              { name = "REDIS_PASSWORD"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }
              { name = "SERVER_URL"; value = "http://image-server.poketwo"; }
              { name = "EXT_SERVER_URL"; value = "https://server.poketwo.io"; }
              { name = "IMGEN_URL"; value = "http://imgen-rust.poketwo"; }
              { name = "API_GATEWAY"; value = "ws://gateway-proxy"; }
            ];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };
  };
}
