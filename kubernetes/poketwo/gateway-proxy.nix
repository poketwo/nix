{ ... }:

{
  namespaces.poketwo = {
    resources = {
      "apps/v1".Deployment.gateway-proxy.spec = {
        replicas = 1;
        selector.matchLabels.app = "gateway-proxy";
        template = {
          metadata.labels.app = "gateway-proxy";
          spec = {
            containers = [{
              name = "server";
              image = "ghcr.io/poketwo/gateway-proxy:latest";
              ports = [{ containerPort = 7878; }];
              resources = {
                limits = { memory = "120Gi"; };
                requests = { memory = "120Gi"; cpu = "500m"; };
              };
              readinessProbe = {
                httpGet = { path = "/metrics"; port = 7878; };
                initialDelaySeconds = 5;
                periodSeconds = 5;
              };
              volumeMounts = [{
                name = "config";
                mountPath = "/config";
              }];
              env = [{ name = "CONFIG"; value = "/config/config.json"; }];
              envFrom = [{ secretRef = { name = "poketwo"; }; }];
            }];
            volumes = [{
              name = "config";
              configMap = { name = "gateway-proxy"; };
            }];
            imagePullSecrets = [{ name = "ghcr-auth"; }];
          };
        };
      };

      v1.Service.gateway-proxy.spec = {
        selector.app = "gateway-proxy";
        ports = [{ port = 7878; }];
      };

      v1.Secret.poketwo.stringData = {
        "TOKEN" = "";
      };

      v1.ConfigMap.gateway-proxy.data = {
        "config.json" = builtins.toJSON {
          log_level = "info";
          shards = 1600;
          intents = 32509;
          port = 7878;
          activity = { type = 0; name = "@Pokétwo help"; };
          status = "online";
          backpressure = 100;
          validate_token = true;
          externally_accessible_url = "ws://gateway-proxy.poketwo.svc.cluster.local:7878";
          cache = {
            channels = true;
            presences = false;
            emojis = false;
            current_member = true;
            members = false;
            roles = true;
            scheduled_events = false;
            stage_instances = false;
            stickers = false;
            users = true;
            voice_states = false;
          };
        };
      };
    };
  };
}
