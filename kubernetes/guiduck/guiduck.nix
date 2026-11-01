{ ... }:

{
  namespaces.guiduck = {
    resources."apps/v1".StatefulSet.guiduck.spec = {
      replicas = 1;
      selector.matchLabels.app = "guiduck";
      serviceName = "guiduck";
      template = {
        metadata.labels.app = "guiduck";
        spec = {
          containers.guiduck = {
            image = "ghcr.io/poketwo/guiduck:latest";
            imagePullPolicy = "Always";
            resources = {
              limits = { memory = "4Gi"; cpu = "500m"; };
              requests = { memory = "4Gi"; cpu = "500m"; };
            };
            env = {
              BOT_TOKEN.valueFrom.secretKeyRef = { name = "guiduck"; key = "token"; };
              PREFIX.value = "? >";
              MESSAGE_CONTENT_INTENT.value = "1";

              DATABASE_HOST.value = "mongodb-0.mongodb-svc,mongodb-1.mongodb-svc,mongodb-2.mongodb-svc";
              DATABASE_USERNAME.value = "guiduck";
              DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "mongodb-user"; key = "password"; };
              DATABASE_NAME.value = "support";
              DATABASE_URI.value = "mongodb://$(DATABASE_USERNAME):$(DATABASE_PASSWORD)@$(DATABASE_HOST)/?authSource=admin&authMechanism=SCRAM-SHA-256&tls=true&tlsAllowInvalidCertificates=true";

              POKETWO_DATABASE_HOST.value = "mongodb-0-external.poketwo,mongodb-1-external.poketwo";
              POKETWO_DATABASE_USERNAME.value = "root";
              POKETWO_DATABASE_PASSWORD.valueFrom.secretKeyRef = { name = "guiduck"; key = "poketwo-mongodb-password"; };
              POKETWO_DATABASE_NAME.value = "pokemon";

              REDIS_URI.value = "redis://redis-master";
              REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "redis"; key = "redis-password"; };
              POKETWO_REDIS_URI.value = "redis://valkey-haproxy.poketwo";
              POKETWO_REDIS_PASSWORD.valueFrom.secretKeyRef = { name = "gateway-cache"; key = "redis-password"; };
              OUTLINE_BASE_URL.value = "https://outline.poketwo.io";
              OUTLINE_API_TOKEN.valueFrom.secretKeyRef = { name = "guiduck"; key = "outline-api-token"; };
              MESSAGE_LOG_KEY.valueFrom.secretKeyRef = { name = "guiduck"; key = "message-log-key"; };
            };
          };
          imagePullSecrets = [{ name = "ghcr-auth"; }];
        };
      };
    };

    resources.v1.Secret.guiduck = {
      type = "Opaque";
      stringData = {
        mongodb-password = "";
        poketwo-mongodb-password = "";
        token = "";
        redis-password = "";
        outline-api-token = "";
        message-log-key = "";
      };
    };

    # The shared Pokétwo Valkey password, read from its Vault entry in the poketwo namespace.
    resources."secrets.hashicorp.com/v1beta1".VaultStaticSecret.gateway-cache.spec = {
      type = "kv-v2";
      mount = "hfym-ds";
      path = "poketwo/gateway-cache";
      destination = { name = "gateway-cache"; create = true; type = "Opaque"; };
    };
  };
}
