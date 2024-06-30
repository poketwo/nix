{ ... }:

let
  env = name: value: { inherit name value; };

  envFromSecretKeyRef = name: secretKeyRef: {
    inherit name;
    valueFrom = { inherit secretKeyRef; };
  };
in
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
            image = "ghcr.io/poketwo/guiduck:master";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; cpu = "500m"; };
              requests = { memory = "4Gi"; cpu = "500m"; };
            };
            env = [
              (envFromSecretKeyRef "BOT_TOKEN" { name = "guiduck"; key = "token"; })
              (env "PREFIX" "? >")

              (env "DATABASE_HOST" "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc")
              (env "DATABASE_USERNAME" "guiduck")
              (env "DATABASE_NAME" "support")
              (envFromSecretKeyRef "DATABASE_PASSWORD" { name = "mongodb-user"; key = "password"; })
              (env "DATABASE_URI" "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&authMechanism=SCRAM-SHA-256&tls=true&tlsAllowInvalidCertificates=true")

              (env "POKETWO_DATABASE_HOST" "mongodb-0.svc-legacy.poketwo.io,monogdb-1.svc-legacy.poketwo.io")
              (env "POKETWO_DATABASE_USERNAME" "root")
              (envFromSecretKeyRef "POKETWO_DATABASE_PASSWORD" { name = "guiduck"; key = "poketwo-mongodb-password"; })
              (env "POKETWO_DATABASE_NAME" "pokemon")

              (env "REDIS_URI" "redis://[64:ff9b::204.16.243.197]/1")
              (env "POKETWO_REDIS_URI" "redis://[64:ff9b::204.16.243.197]/0")
              (env "OUTLINE_BASE_URL" "https://outline.poketwo.io")

              (envFromSecretKeyRef "REDIS_PASSWORD" { name = "guiduck"; key = "redis-password"; })
              (envFromSecretKeyRef "POKETWO_REDIS_PASSWORD" { name = "guiduck"; key = "poketwo-redis-password"; })
              (envFromSecretKeyRef "OUTLINE_API_TOKEN" { name = "guiduck"; key = "outline-api-token"; })
            ];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources.v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
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
