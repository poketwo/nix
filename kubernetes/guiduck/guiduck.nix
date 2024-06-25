{ lib, ... }:

let
  secretKeyRefsAttrsToList = attrs: map
    ({ name, value }: { inherit name; valueFrom.secretKeyRef = value; })
    (lib.attrsToList attrs);
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
            env = builtins.concatLists [
              (lib.attrsToList {
                DATABASE_HOST = "mongodb-public-0.svc-legacy.poketwo.io,mongodb-public-1.svc-legacy.poketwo.io";
                DATABASE_USERNAME = "root";
                DATABASE_NAME = "support";
                POKETWO_DATABASE_HOST = "mongodb-0.svc-legacy.poketwo.io,monogdb-1.svc-legacy.poketwo.io";
                POKETWO_DATABASE_USERNAME = "root";
                POKETWO_DATABASE_NAME = "pokemon";
                PREFIX = "? >";
                REDIS_URI = "redis://[64:ff9b::204.16.243.197]/1";
                POKETWO_REDIS_URI = "redis://[64:ff9b::204.16.243.197]/0";
                OUTLINE_BASE_URL = "https://outline.poketwo.io";
              })
              (secretKeyRefsAttrsToList {
                DATABASE_PASSWORD = { name = "guiduck"; key = "mongodb-password"; };
                POKETWO_DATABASE_PASSWORD = { name = "guiduck"; key = "poketwo-mongodb-password"; };
                BOT_TOKEN = { name = "guiduck"; key = "token"; };
                REDIS_PASSWORD = { name = "guiduck"; key = "redis-password"; };
                POKETWO_REDIS_PASSWORD = { name = "guiduck"; key = "poketwo-redis-password"; };
                OUTLINE_API_TOKEN = { name = "guiduck"; key = "outline-api-token"; };
              })
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
