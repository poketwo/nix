{ ... }:

let
  # Two colours of the same bot so a roll has no gap: scale the idle one up, wait for Ready,
  # scale the live one down. New pods stand by at the gateway's /handoff path and take each
  # shard over the moment the old pod's connection closes.
  # No `replicas`: rolls are `kubectl scale`, and leaving the field out keeps Argo's syncs off it.
  cluster = colour: {
    selector.matchLabels = {
      app = "poketwo";
      inherit colour;
    };
    serviceName = "poketwo";
    podManagementPolicy = "Parallel";
    template = {
      metadata.labels = {
        app = "poketwo";
        inherit colour;
      };
      spec = {
        containers.poketwo = {
          image = "ghcr.io/poketwo/poketwo:production";
          imagePullPolicy = "Always";
          resources = {
            limits = { memory = "4Gi"; };
            requests = { memory = "2Gi"; cpu = "100m"; };
          };
          # The bot writes /tmp/ready once all of its shards are ready.
          readinessProbe = {
            exec.command = [ "test" "-f" "/tmp/ready" ];
            periodSeconds = 5;
          };
          envFrom = [{ secretRef.name = "poketwo"; }];
          env = {
            DATABASE_HOST.value = "mongodb-0.mongodb-headless,mongodb-1.mongodb-headless/?replicaSet=poketwo&w=1&maxPoolSize=10";
            DATABASE_USERNAME.value = "root";
            DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "mongodb"; key = "mongodb-root-password"; };
            DATABASE_NAME.value = "pokemon";
            REDIS_URI.value = "redis://valkey-haproxy";
            REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-cache"; key = "redis-password"; };

            NUM_SHARDS.value = "1600";
            NUM_CLUSTERS.value = "200";
            CLUSTER_NAME.valueFrom.fieldRef.fieldPath = "metadata.name";
            # CLUSTER_NAME.value = "poketwo-199";

            SERVER_URL.value = "http://image-server";
            EXT_SERVER_URL.value = "https://server.poketwo.io";
            IMGEN_URL.value = "http://imgen-rust";
            API_GATEWAY.value = "ws://gateway/handoff";
            MALLOC_CONF.value = "background_thread:true";
          };
        };
        imagePullSecrets = [{ name = "ghcr-auth"; }];
      };
    };
  };
in
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

      "apps/v1".StatefulSet.poketwo-a.spec = cluster "a";
      "apps/v1".StatefulSet.poketwo-b.spec = cluster "b";
    };
  };
}
