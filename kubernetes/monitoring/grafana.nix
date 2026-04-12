{ transpire, ... }:

{
  namespaces.grafana = {
    helmReleases.grafana = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "grafana";
        version = "8.0.2";
        sha256 = "ZavFvU7bKimvNOwCsIi5deO78UXdlWzkMp/6YTPgII4=";
      };

      values = {
        admin = {
          existingSecret = "grafana-admin";
          userKey = "admin-user";
          passwordKey = "admin-password";
        };

        persistence = {
          enabled = true;
          size = "30Gi";
        };

        datasources."datasources.yaml" = {
          apiVersion = 1;
          datasources = [
            { name = "Mimir"; type = "prometheus"; url = "http://mimir-gateway.mimir.svc.cluster.local/prometheus"; }
            { name = "Loki"; type = "loki"; url = "http://loki-gateway.loki.svc.cluster.local"; }
          ];
        };

        "grafana.ini" = {
          server.root_url = "https://grafana.hfym.co";
          "auth.generic_oauth" = {
            enabled = true;
            name = "Pokétwo";
            allow_sign_up = true;
            auto_login = true;
            client_id = "grafana.hfym.co";
            scopes = "openid email profile";
            auth_url = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/auth";
            token_url = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/token";
            api_url = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/userinfo";
            role_attribute_path = "'Editor'";
          };
        };

        envFromSecrets = [{
          name = "grafana-oidc";
          optional = false;
        }];

        ingress = {
          enabled = true;
          annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
          hosts = [ "grafana.hfym.co" ];
          tls = [{
            hosts = [ "grafana.hfym.co" ];
            secretName = "grafana-tls";
          }];
        };
      };
    };

    resources.v1.Secret.grafana-admin = {
      type = "Opaque";
      stringData = {
        admin-user = "admin";
        admin-password = "";
      };
    };

    resources.v1.Secret.grafana-oidc = {
      type = "Opaque";
      stringData = {
        GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "";
      };
    };
  };
}
