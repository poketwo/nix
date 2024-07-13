{ ... }:

let
  makeLoadBalancer = index: {
    metadata.annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = "mongodb-${index}-external.guiduck.ds.hfym.co";
      "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false";
    };
    spec = {
      selector = {
        app = "mongodb-svc";
        "statefulset.kubernetes.io/pod-name" = "mongodb-${index}";
      };
      ports = [{ port = 27017; }];
      type = "LoadBalancer";
    };
  };
in
{
  namespaces.guiduck = {
    resources."cert-manager.io/v1".Certificate.mongodb-tls.spec = {
      commonName = "*.mongodb-svc.guiduck.svc.cluster.local";
      dnsNames = [ "*.mongodb-svc.guiduck.svc.cluster.local" ];
      secretName = "mongodb-tls";
      issuerRef = {
        name = "cluster-ca";
        kind = "ClusterIssuer";
      };
    };

    resources."mongodbcommunity.mongodb.com/v1".MongoDBCommunity.mongodb.spec = {
      type = "ReplicaSet";
      members = 3;
      version = "7.0.11";
      security.tls = {
        enabled = true;
        certificateKeySecretRef.name = "mongodb-tls";
        caCertificateSecretRef.name = "cluster-ca";
      };
      users = [{
        name = "guiduck";
        scramCredentialsSecretName = "guiduck";
        passwordSecretRef.name = "mongodb-user";
        roles = [{ name = "root"; db = "admin"; }];
      }];
      additionalMongodConfig."net.ipv6" = true;
      statefulSet.spec = {
        volumeClaimTemplates = [{
          metadata.name = "data-volume";
          spec = {
            resources.requests.storage = "256Gi";
            storageClassName = "rbd-nvme-retain";
          };
        }];
        template.spec = {
          containers = [{
            name = "mongod";
            resources = {
              limits = { cpu = 1; memory = "20Gi"; };
              requests = { cpu = "100m"; memory = "1Gi"; };
            };
          }];
        };
      };
      replicaSetHorizons = [
        { external = "mongodb-0-external.guiduck.ds.hfym.co:27017"; }
        { external = "mongodb-1-external.guiduck.ds.hfym.co:27017"; }
        { external = "mongodb-2-external.guiduck.ds.hfym.co:27017"; }
      ];
    };

    resources.v1.Secret."mongodb-user" = {
      type = "Opaque";
      stringData.password = "";
    };

    resources.v1.Service = builtins.listToAttrs (map
      (index: {
        name = "mongodb-${index}-external";
        value = makeLoadBalancer index;
      }) [ "0" "1" "2" ]);

    resources."cilium.io/v2".CiliumNetworkPolicy.allow-ingress-to-mongodb.spec = {
      endpointSelector.matchLabels.app = "mongodb-svc";
      ingress = [{ fromEntities = [ "all" ]; }];
    };
  };
}
