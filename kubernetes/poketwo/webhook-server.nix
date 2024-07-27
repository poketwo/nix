{ ... }:

{
  namespaces.poketwo = {
    resources."apps/v1".Deployment.webhook-server.spec = {
      replicas = 4;
      selector.matchLabels.app = "webhook-server";
      template = {
        metadata.labels.app = "webhook-server";
        spec = {
          containers = [{
            name = "server";
            image = "ghcr.io/poketwo/webhook-server:latest";
            ports = [{ containerPort = 8000; }];
            resources = {
              limits = { memory = "100Mi"; };
              requests = { memory = "10Mi"; cpu = "50m"; };
            };
            readinessProbe = {
              httpGet = { path = "/"; port = 8000; };
              initialDelaySeconds = 5;
              periodSeconds = 5;
            };
            env = [
              { name = "DATABASE_HOST"; value = "mongodb-0.mongodb-headless,mongodb-1.mongodb-headless/?replicaSet=poketwo"; }
              { name = "DATABASE_USERNAME"; value = "root"; }
              { name = "DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "mongodb"; key = "mongodb-root-password"; }; }
              { name = "DATABASE_NAME"; value = "pokemon"; }
              { name = "REDIS_URI"; value = "redis://redis-master"; }
              { name = "REDIS_PASSWORD"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }
            ];
            envFrom = [{ secretRef.name = "webhook-server"; }];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources."networking.k8s.io/v1".Ingress.webhook-server-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "webhooks.poketwo.io";
          http = {
            paths = [{
              path = "/";
              pathType = "Prefix";
              backend.service = { name = "webhook-server"; port.number = 80; };
            }];
          };
        }];
        tls = [{
          hosts = [ "webhooks.poketwo.io" ];
          secretName = "webhook-server-ingress-tls";
        }];
      };
    };

    resources.v1.Secret.webhook-server.stringData = {
      CAPTCHA_SECRET = "";
      DBL_SECRET = "";
      STRIPE_KEY = "";
      STRIPE_SECRET = "";
    };

    resources.v1.Service.webhook-server.spec = {
      selector.app = "webhook-server";
      ports = [{ port = 80; targetPort = 8000; }];
    };
  };
}
