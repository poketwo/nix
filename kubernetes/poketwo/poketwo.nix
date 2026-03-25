{ ... }:

{
  namespaces.poketwo = {
    resources = {
      v1.Secret.poketwo.stringData = {
        BOT_TOKEN = "";
        DBL_TOKEN = "";
      };

      v1.Service.poketwo.spec = {
        selector.app = "poketwo";
        clusterIP = "None";
      };

      "apps/v1".StatefulSet.poketwo.spec = {
        replicas = 200;
        selector.matchLabels.app = "poketwo";
        serviceName = "poketwo";
        podManagementPolicy = "Parallel";
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
                { name = "DATABASE_HOST"; value = "mongodb-0.mongodb-headless,mongodb-1.mongodb-headless/?replicaSet=poketwo"; }
                { name = "DATABASE_USERNAME"; value = "root"; }
                { name = "DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "mongodb"; key = "mongodb-root-password"; }; }
                { name = "DATABASE_NAME"; value = "pokemon"; }
                { name = "REDIS_URI"; value = "redis://redis-master"; }
                { name = "REDIS_PASSWORD"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }

                { name = "NUM_SHARDS"; value = "1600"; }
                { name = "NUM_CLUSTERS"; value = "200"; }
                { name = "CLUSTER_NAME"; valueFrom.fieldRef.fieldPath = "metadata.name"; }
                # { name = "CLUSTER_NAME"; value = "poketwo-199"; }

                { name = "SERVER_URL"; value = "http://image-server"; }
                { name = "EXT_SERVER_URL"; value = "https://server.poketwo.io"; }
                { name = "IMGEN_URL"; value = "http://imgen-rust"; }
                { name = "API_GATEWAY"; value = "ws://gateway-proxy"; }
              ];
            }];
            imagePullSecrets = [{ name = "ghcr-auth"; }];
          };
        };
      };
    };
  };
}
