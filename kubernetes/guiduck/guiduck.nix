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
          containers = [{
            name = "guiduck";
            image = "ghcr.io/poketwo/guiduck:latest";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; cpu = "500m"; };
              requests = { memory = "4Gi"; cpu = "500m"; };
            };
            env = [
              { name = "BOT_TOKEN"; valueFrom.secretKeyRef = { name = "guiduck"; key = "token"; }; }
              { name = "PREFIX"; value = "? >"; }

              { name = "DATABASE_HOST"; value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc"; }
              { name = "DATABASE_USERNAME"; value = "guiduck"; }
              { name = "DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; }; }
              { name = "DATABASE_NAME"; value = "support"; }
              { name = "DATABASE_URI"; value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&authMechanism=SCRAM-SHA-256&tls=true&tlsAllowInvalidCertificates=true"; }

              { name = "POKETWO_DATABASE_HOST"; value = "mongodb-0-external.poketwo,mongodb-1-external.poketwo"; }
              { name = "POKETWO_DATABASE_USERNAME"; value = "root"; }
              { name = "POKETWO_DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-mongodb-password"; }; }
              { name = "POKETWO_DATABASE_NAME"; value = "pokemon"; }

              { name = "REDIS_URI"; value = "redis://redis-master"; }
              { name = "REDIS_PASSWORD"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }
              { name = "POKETWO_REDIS_URI"; value = "redis://redis-master.poketwo"; }
              { name = "POKETWO_REDIS_PASSWORD"; valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-redis-password"; }; }
              { name = "OUTLINE_BASE_URL"; value = "https://outline.poketwo.io"; }
              { name = "OUTLINE_API_TOKEN"; valueFrom.secretKeyRef = { name = "guiduck"; key = "outline-api-token"; }; }
            ];
          }];
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
