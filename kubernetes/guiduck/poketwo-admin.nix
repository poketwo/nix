{ ... }:

{
  namespaces.guiduck = {
    resources."apps/v1".Deployment.poketwo-admin.spec = {
      replicas = 1;
      selector.matchLabels.app = "poketwo-admin";
      template = {
        metadata.labels.app = "poketwo-admin";
        spec = {
          containers = [{
            name = "poketwo-admin";
            image = "ghcr.io/poketwo/admin.poketwo.net:latest";
            imagePullPolicy = "Always";
            env = [
              { name = "NEXT_PUBLIC_BASE_URL"; value = "https://admin.poketwo.net"; }

              { name = "DATABASE_HOST"; value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc"; }
              { name = "DATABASE_USERNAME"; value = "guiduck"; }
              { name = "DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; }; }
              { name = "DATABASE_NAME"; value = "support"; }
              { name = "DATABASE_URI"; value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&tls=true&tlsAllowInvalidCertificates=true"; }

              { name = "SECRET_KEY"; valueFrom.secretKeyRef = { name = "poketwo-admin"; key = "secret-key"; }; }
              { name = "DISCORD_CLIENT_ID"; valueFrom.secretKeyRef = { name = "poketwo-admin"; key = "discord-client-id"; }; }
              { name = "DISCORD_CLIENT_SECRET"; valueFrom.secretKeyRef = { name = "poketwo-admin"; key = "discord-client-secret"; }; }
            ];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources.v1.Service.poketwo-admin.spec = {
      selector.app = "poketwo-admin";
      ports = [{
        port = 80;
        targetPort = 3000;
      }];
    };

    resources."networking.k8s.io/v1".Ingress.poketwo-admin-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "admin.poketwo.net";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "poketwo-admin";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "admin.poketwo.net" ];
          secretName = "poketwo-admin-ingress-tls";
        }];
      };
    };

    resources.v1.Secret.poketwo-admin = {
      type = "Opaque";
      stringData = {
        secret-key = "";
        discord-client-id = "";
        discord-client-secret = "";
      };
    };
  };
}
