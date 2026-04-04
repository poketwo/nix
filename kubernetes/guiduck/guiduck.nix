{ ... }:

{
  namespaces.guiduck = {
    resources."apps/v1".StatefulSet.guiduck.spec = {
      replicas = 1;
      selector.matchLabels.app = "guiduck";
      serviceName = "guiduck";
      template = {
        metadata.labels.app = "guiduck";
        spec = {
          containers.guiduck = {
            image = "ghcr.io/poketwo/guiduck:latest";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; cpu = "500m"; };
              requests = { memory = "4Gi"; cpu = "500m"; };
            };
            env = {
              BOT_TOKEN.valueFrom.secretKeyRef = { name = "guiduck"; key = "token"; };
              PREFIX.value = "? >";

              DATABASE_HOST.value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc";
              DATABASE_USERNAME.value = "guiduck";
              DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; };
              DATABASE_NAME.value = "support";
              DATABASE_URI.value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&authMechanism=SCRAM-SHA-256&tls=true&tlsAllowInvalidCertificates=true";

              POKETWO_DATABASE_HOST.value = "mongodb-0-external.poketwo,mongodb-1-external.poketwo";
              POKETWO_DATABASE_USERNAME.value = "root";
              POKETWO_DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-mongodb-password"; };
              POKETWO_DATABASE_NAME.value = "pokemon";

              REDIS_URI.value = "redis://redis-master";
              REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };
              POKETWO_REDIS_URI.value = "redis://redis-master.poketwo";
              POKETWO_REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-redis-password"; };
              OUTLINE_BASE_URL.value = "https://outline.poketwo.io";
              OUTLINE_API_TOKEN.valueFrom.secretKeyRef = { name = "guiduck"; key = "outline-api-token"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources.v1.Secret.guiduck = {
      type = "Opaque";
      stringData = {
        mongodb-password = "";
        poketwo-mongodb-password = "";
        token = "";
        redis-password = "";
        poketwo-redis-password = "";
        outline-api-token = "";
      };
    };
  };
}
