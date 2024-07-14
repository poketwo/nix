{
  namespaces.poketwo = {
    resources = {
      "apps/v1".Deployment.gateway-proxy.spec = {
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
                mountPath = "/config.json";
                subPath = "config.json";
              }];
            }];
            volumes = [{
              name = "config";
              secret = { secretName = "gateway-proxy"; };
            }];
            imagePullSecrets = [{ name = "ghcr-auth"; }];
          };
        };
      };

      v1.Service.gateway-proxy.spec = {
        selector.app = "gateway-proxy";
        ports = [{ port = 7878; }];
      };

      v1.Secret.gateway-proxy.stringData = {
        "config.json" = "";
      };
    };
  };
}
