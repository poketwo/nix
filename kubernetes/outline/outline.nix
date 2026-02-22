{ transpire, ... }:

let
  env = [
    { name = "URL"; value = "https://outline.poketwo.io"; }
    { name = "PORT"; value = "3000"; }

    { name = "REDIS_PASS"; valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; }; }
    { name = "REDIS_URL"; value = "redis://:$(REDIS_PASS)@redis-master:6379/?family=6"; }

    { name = "DB_USER"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "username"; }; }
    { name = "DB_PASS"; valueFrom.secretKeyRef = { name = "postgres-app"; key = "password"; }; }
    { name = "DATABASE_URL"; value = "postgres://$(DB_USER):$(DB_PASS)@postgres-rw:5432/outline"; }

    { name = "AWS_ACCESS_KEY_ID"; valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_ACCESS_KEY_ID"; }; }
    { name = "AWS_SECRET_ACCESS_KEY"; valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_SECRET_ACCESS_KEY"; }; }
    { name = "AWS_S3_UPLOAD_BUCKET_NAME"; valueFrom.configMapKeyRef = { name = "outline-bucket"; key = "BUCKET_NAME"; }; }
    { name = "AWS_S3_UPLOAD_BUCKET_URL"; value = "https://rgw.hfym.co"; }
    { name = "AWS_S3_ACL"; value = "private"; }

    { name = "OIDC_CLIENT_ID"; value = "outline.poketwo.io"; }
    { name = "OIDC_AUTH_URI"; value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/auth"; }
    { name = "OIDC_TOKEN_URI"; value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/token"; }
    { name = "OIDC_USERINFO_URI"; value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/userinfo"; }
    { name = "OIDC_DISPLAY_NAME"; value = "Pokétwo"; }
  ];

  envFrom = [{ secretRef.name = "outline"; }];
in
{
  namespaces.outline = {
    helmReleases.redis = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "redis";
        version = "19.6.1";
        sha256 = "z7M/oHv2x9LVaMaPXk5KfYYqZs7m7+PmLxnKjL0Thxs=";
      };

      values = {
        global.imageRegistry = "docker.io/bitnamilegacy";
        architecture = "standalone";
        master.persistence.size = "1Gi";
        metrics.enabled = true;
        networkPolicy.enabled = false;
      };
    };

    resources."apps/v1".Deployment.outline.spec = {
      replicas = 1;
      selector.matchLabels.app = "outline";
      template = {
        metadata.labels.app = "outline";
        spec = {
          containers = [{
            name = "outline";
            image = "outlinewiki/outline:0.71.0";
            ports = [{ containerPort = 3000; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { memory = "1Gi"; cpu = "100m"; };
            };
            inherit env envFrom;
          }];
          initContainers = [{
            name = "migrate";
            image = "outlinewiki/outline:0.66.3";
            command = [ "yarn" ];
            args = [ "db:migrate" "--env=production" ];
            inherit env envFrom;
          }];
        };
      };
    };

    resources."networking.k8s.io/v1".Ingress.outline-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "outline.poketwo.io";
          http = {
            paths = [{
              path = "/";
              pathType = "Prefix";
              backend.service = { name = "outline"; port.number = 80; };
            }];
          };
        }];
        tls = [{
          hosts = [ "outline.poketwo.io" ];
          secretName = "outline-ingress-tls";
        }];
      };
    };

    resources."postgresql.cnpg.io/v1".Cluster.postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "outline";
      storage.size = "8Gi";
    };

    resources."objectbucket.io/v1alpha1".ObjectBucketClaim.outline-bucket.spec = {
      generateBucketName = "outline";
      storageClassName = "rgw-nvme";
    };

    resources.v1.Service.outline.spec = {
      selector = { app = "outline"; };
      ports = [{ port = 80; targetPort = 3000; }];
    };

    resources.v1.Secret.outline.stringData = {
      SECRET_KEY = "";
      UTILS_SECRET = "";
      OIDC_CLIENT_SECRET = "";
    };
  };
}
