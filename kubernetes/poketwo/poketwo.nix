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
            containers.poketwo = {
              image = "ghcr.io/poketwo/poketwo:production";
              imagePullPolicy = "Always";
              resources = {
                limits = { memory = "4Gi"; };
                requests = { memory = "2Gi"; cpu = "100m"; };
              };
              envFrom = [{ secretRef.name = "poketwo"; }];
              env = {
                DATABASE_HOST.value = "mongodb-0.mongodb-headless,mongodb-1.mongodb-headless/?replicaSet=poketwo&w=1&maxPoolSize=10";
                DATABASE_USERNAME.value = "root";
                DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "mongodb"; key = "mongodb-root-password"; };
                DATABASE_NAME.value = "pokemon";
                REDIS_URI.value = "redis://redis-master";
                REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };

                NUM_SHARDS.value = "1600";
                NUM_CLUSTERS.value = "200";
                CLUSTER_NAME.valueFrom.fieldRef.fieldPath = "metadata.name";
                # CLUSTER_NAME.value = "poketwo-199";

                SERVER_URL.value = "http://image-server";
                EXT_SERVER_URL.value = "https://server.poketwo.io";
                IMGEN_URL.value = "http://imgen-rust";
                API_GATEWAY.value = "ws://gateway-proxy";
              };
            };
            imagePullSecrets = [{ name = "ghcr-auth"; }];
          };
        };
      };
    };
  };
}
