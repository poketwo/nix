{ ... }:

{
  namespaces.poketwo-staging-private.resources = {
    "mongodbcommunity.mongodb.com/v1".MongoDBCommunity.mongodb.spec = {
      type = "ReplicaSet";
      members = 3;
      version = "7.0.11";
      security = { };
      users = [{
        name = "poketwo";
        scramCredentialsSecretName = "poketwo";
        passwordSecretRef.name = "mongodb-user";
        roles = [{ name = "root"; db = "admin"; }];
      }];
      additionalMongodConfig."net.ipv6" = true;
      statefulSet.spec = {
        volumeClaimTemplates = [{
          metadata.name = "data-volume";
          spec = {
            resources.requests.storage = "8Gi";
            storageClassName = "rbd-nvme-retain";
          };
        }];
        template.spec.containers = [{
          name = "mongod";
          resources = {
            limits = { cpu = 1; memory = "20Gi"; };
            requests = { cpu = "100m"; memory = "1Gi"; };
          };
        }];
      };
    };

    v1.Secret."mongodb-user" = {
      type = "Opaque";
      stringData.password = "";
    };
  };
}
