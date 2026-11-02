{ transpire, ... }:

{
  namespaces.grafana = {
    helmReleases.grafana = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana-community.github.io/helm-charts";
        name = "grafana";
        version = "12.0.0";
        sha256 = "eqSidrI/OWupasKaL9a9npgwjtB3jCocHBIVjL0SnlM=";
      };

      values = {
        image.tag = "13.0.1";

        deploymentStrategy = {
          type = "Recreate";
          rollingUpdate = null;
        };

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

        # Charts ship their dashboards as ConfigMaps labelled grafana_dashboard
        # (cilium, mimir, loki); the annotation picks the folder.
        sidecar.dashboards = {
          enabled = true;
          searchNamespace = "ALL";
          resource = "configmap";
          label = "grafana_dashboard";
          labelValue = "1";
          folderAnnotation = "k8s-sidecar-target-directory";
          provider.foldersFromFilesStructure = true;
        };

        # The chart's ClusterRole would also grant cluster-wide secret reads.
        rbac.useExistingClusterRole = "grafana-dashboard-reader";

        dashboardProviders."dashboardproviders.yaml" = {
          apiVersion = 1;
          providers = [{
            name = "infrastructure";
            orgId = 1;
            folder = "Infrastructure";
            type = "file";
            disableDeletion = true;
            editable = false;
            options.path = "/var/lib/grafana/dashboards/infrastructure";
          }];
        };

        # Downloaded from grafana.com by the chart's init container.
        dashboards.infrastructure = {
          node-exporter-full = { gnetId = 1860; revision = 46; datasource = "Mimir"; };
          ceph-cluster = { gnetId = 2842; revision = 18; datasource = "Mimir"; };
        };

        "grafana.ini" = {
          server.root_url = "https://grafana.hfym.co";
          explore.enabled = true;
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
            role_attribute_path = "to_string('Admin')";
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

    resources."rbac.authorization.k8s.io/v1".ClusterRole.grafana-dashboard-reader.rules = [{
      apiGroups = [ "" ];
      resources = [ "configmaps" ];
      verbs = [ "get" "watch" "list" ];
    }];

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
