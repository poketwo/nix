{ ... }:

{
  namespaces.poketwo.resources = {
    "apps/v1".StatefulSet.gateway-redis.spec = {
      replicas = 1;
      selector.matchLabels.app = "gateway-redis";
      serviceName = "gateway-redis";
      template = {
        metadata.labels.app = "gateway-redis";
        spec = {
          securityContext = { runAsUser = 999; runAsGroup = 999; fsGroup = 999; };
          containers = {
            valkey = {
              image = "valkey/valkey:8.1.9";
              args = [
                "--requirepass" "$(VALKEY_PASSWORD)"
                "--save" "60" "1"
                "--appendonly" "no"
                "--maxmemory-policy" "noeviction"
              ];
              env.VALKEY_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-redis"; key = "redis-password"; };
              ports = [{ name = "valkey"; containerPort = 6379; }];
              readinessProbe.tcpSocket.port = "valkey";
              resources = {
                requests = { memory = "20Gi"; };
                limits = { memory = "20Gi"; cpu = "1000m"; };
              };
              volumeMounts = [{ name = "data"; mountPath = "/data"; }];
            };
            metrics = {
              image = "oliver006/redis_exporter:v1.95.0";
              env = {
                REDIS_ADDR.value = "redis://localhost:6379";
                REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-redis"; key = "redis-password"; };
              };
              ports = [{ name = "metrics"; containerPort = 9121; }];
              resources = {
                requests = { memory = "32Mi"; cpu = "10m"; };
                limits = { memory = "128Mi"; cpu = "100m"; };
              };
            };
          };
          terminationGracePeriodSeconds = 120;
        };
      };
      volumeClaimTemplates = [{
        metadata.name = "data";
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "rbd-nvme";
          resources.requests.storage = "40Gi";
        };
      }];
    };

    v1.Service.gateway-redis.spec = {
      selector.app = "gateway-redis";
      ports = [{ name = "valkey"; port = 6379; targetPort = "valkey"; }];
    };

    v1.Secret.gateway-redis.stringData = {
      redis-password = "";
    };
  };
}
