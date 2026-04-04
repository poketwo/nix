{ ... }:

{
  namespaces.guiduck = {
    resources."apps/v1".Deployment.poketwo-forms.spec = {
      replicas = 1;
      selector.matchLabels.app = "poketwo-forms";
      template = {
        metadata.labels.app = "poketwo-forms";
        spec = {
          containers.poketwo-forms = {
            image = "ghcr.io/poketwo/forms.poketwo.net:latest";
            imagePullPolicy = "Always";
            env = {
              DATABASE_HOST.value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc";
              DATABASE_USERNAME.value = "guiduck";
              DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; };
              DATABASE_NAME.value = "support";
              DATABASE_URI.value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&tls=true&tlsAllowInvalidCertificates=true";

              POKETWO_DATABASE_HOST.value = "mongodb-0-external.poketwo,mongodb-1-external.poketwo";
              POKETWO_DATABASE_USERNAME.value = "root";
              POKETWO_DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-mongodb-password"; };
              POKETWO_DATABASE_NAME.value = "pokemon";
              POKETWO_DATABASE_URI.value = "mongodb://$(POKETWO_DATABASE_USERNAME):$(POKETWO_DATABASE_PASSWORD)@$(POKETWO_DATABASE_HOST)";

              SECRET_KEY.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "secret-key"; };
              SENDGRID_KEY.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "sendgrid-key"; };
              NEXT_PUBLIC_FORMIUM_PROJECT_ID.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "formium-project-id"; };
              FORMIUM_TOKEN.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "formium-token"; };
              DISCORD_CLIENT_ID.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "discord-client-id"; };
              DISCORD_CLIENT_SECRET.valueFrom.secretKeyRef = { name = "poketwo-forms"; key = "discord-client-secret"; };

              # FIXME: Remove this when Formium fixes their site
              NODE_TLS_REJECT_UNAUTHORIZED.value = "0";
            };
          };
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
