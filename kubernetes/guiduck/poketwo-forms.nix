{ ... }:

{
  namespaces.guiduck = {
    resources."apps/v1".Deployment.poketwo-forms.spec = {
      replicas = 1;
      selector.matchLabels.app = "poketwo-forms";
      template = {
        metadata.labels.app = "poketwo-forms";
        spec = {
          containers = [{
            name = "poketwo-forms";
            image = "ghcr.io/poketwo/forms.poketwo.net:latest";
            imagePullPolicy = "Always";
            env = [
              { name = "DATABASE_HOST"; value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc"; }
              { name = "DATABASE_USERNAME"; value = "guiduck"; }
              { name = "DATABASE_PASSWORD"; valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; }; }
              { name = "DATABASE_NAME"; value = "support"; }
              { name = "DATABASE_URI"; value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&tls=true&tlsAllowInvalidCertificates=true"; }

              { name = "SECRET_KEY"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "secret-key"; }; }
              { name = "SENDGRID_KEY"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "sendgrid-key"; }; }
              { name = "NEXT_PUBLIC_FORMIUM_PROJECT_ID"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "formium-project-id"; }; }
              { name = "FORMIUM_TOKEN"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "formium-token"; }; }
              { name = "DISCORD_CLIENT_ID"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "discord-client-id"; }; }
              { name = "DISCORD_CLIENT_SECRET"; valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "discord-client-secret"; }; }
            ];
          }];
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources.v1.Service.poketwo-forms.spec = {
      selector.app = "poketwo-forms";
      ports = [{
        port = 80;
        targetPort = 3000;
      }];
    };

    resources."networking.k8s.io/v1".Ingress.poketwo-forms-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "forms.poketwo.net";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "poketwo-forms";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "forms.poketwo.net" ];
          secretName = "poketwo-forms-ingress-tls";
        }];
      };
    };

    resources.v1.Secret.poketwo-forms = {
      type = "Opaque";
      stringData = {
        secret-key = "";
        sendgrid-key = "";
        formium-project-id = "";
        formium-token = "";
        discord-client-id = "";
        discord-client-secret = "";
      };
    };
  };
}
