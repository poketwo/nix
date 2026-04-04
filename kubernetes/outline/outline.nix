{ transpire, ... }:

let
  env = {
    URL.value = "https://outline.poketwo.io";
    PORT.value = "3000";

    REDIS_PASS.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };
    REDIS_URL.value = "redis://:$(REDIS_PASS)@redis-master:6379/?family=6";

    DB_USER.valueFrom.secretKeyRef = { name = "postgres-app"; key = "username"; };
    DB_PASS.valueFrom.secretKeyRef = { name = "postgres-app"; key = "password"; };
    DATABASE_URL.value = "postgres://$(DB_USER):$(DB_PASS)@postgres-rw:5432/outline";

    AWS_ACCESS_KEY_ID.valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_ACCESS_KEY_ID"; };
    AWS_SECRET_ACCESS_KEY.valueFrom.secretKeyRef = { name = "outline-bucket"; key = "AWS_SECRET_ACCESS_KEY"; };
    AWS_S3_UPLOAD_BUCKET_NAME.valueFrom.configMapKeyRef = { name = "outline-bucket"; key = "BUCKET_NAME"; };
    AWS_S3_UPLOAD_BUCKET_URL.value = "https://rgw.hfym.co";
    AWS_S3_ACL.value = "private";

    OIDC_CLIENT_ID.value = "outline.poketwo.io";
    OIDC_AUTH_URI.value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/auth";
    OIDC_TOKEN_URI.value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/token";
    OIDC_USERINFO_URI.value = "https://auth-dev.poketwo.io/realms/poketwo/protocol/openid-connect/userinfo";
    OIDC_DISPLAY_NAME.value = "Pokétwo";
  };

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
        global.imageRegistry = "docker.io";
        global.security.allowInsecureImages = true;
        image.repository = "bitnamilegacy/redis";
        sentinel.image.repository = "bitnamilegacy/redis-sentinel";
        architecture = "standalone";
        master.persistence.size = "1Gi";
        metrics = {
          enabled = true;
          image.repository = "bitnamilegacy/redis-exporter";
        };
        networkPolicy.enabled = false;
        volumePermissions.image.repository = "bitnamilegacy/os-shell";
        sysctl.image.repository = "bitnamilegacy/os-shell";
        kubectl.image.repository = "bitnamilegacy/kubectl";
      };
    };

    resources."apps/v1".Deployment.outline.spec = {
      replicas = 1;
      selector.matchLabels.app = "outline";
      template = {
        metadata.labels.app = "outline";
        spec = {
          containers.outline = {
            image = "outlinewiki/outline:0.71.0";
            ports = [{ containerPort = 3000; }];
            resources = {
              limits = { memory = "4Gi"; };
              requests = { memory = "1Gi"; cpu = "100m"; };
            };
            inherit env envFrom;
          };
          initContainers.migrate = {
            image = "outlinewiki/outline:0.66.3";
            command = [ "yarn" ];
            args = [ "db:migrate" "--env=production" ];
            inherit env envFrom;
          };
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
