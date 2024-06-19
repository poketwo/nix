{ ... }:

let
  makeLoadBalancer = index: {
    metadata.annotations = {
      "external-dns.alpha.kubernetes.io/hostname" = "mongodb-${index}.guiduck-mongodb.svc.poketwo.io";
      "external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false";
    };
    spec = {
      selector = {
        app = "guiduck-mongodb-svc";
        "statefulset.kubernetes.io/pod-name" = "guiduck-mongodb-${index}";
      };
      ports = [{ port = 27017; }];
      type = "LoadBalancer";
    };
  };
in
{
  namespaces.guiduck = {
    createNamespace = false;

    resources."cert-manager.io/v1".Certificate.guiduck-mongodb-tls.spec = {
      commonName = "*.guiduck-mongodb-svc.guiduck.svc.cluster.local";
      dnsNames = [ "*.guiduck-mongodb-svc.guiduck.svc.cluster.local" ];
      secretName = "guiduck-mongodb-tls";
      issuerRef = {
        name = "cluster-ca";
        kind = "ClusterIssuer";
      };
    };

    resources."mongodbcommunity.mongodb.com/v1".MongoDBCommunity.guiduck-mongodb.spec = {
      type = "ReplicaSet";
      members = 3;
      version = "7.0.11";
      security.tls = {
        enabled = true;
        certificateKeySecretRef.name = "guiduck-mongodb-tls";
        caCertificateSecretRef.name = "cluster-ca";
      };
      users = [{
        name = "guiduck";
        scramCredentialsSecretName = "guiduck";
        passwordSecretRef.name = "guiduck-mongodb-user";
        roles = [{ name = "root"; db = "admin"; }];
      }];
      additionalMongodConfig."net.ipv6" = true;
      statefulSet.spec.template.spec = {
        volumeClaimTemplates = [{
          metadata.name = "data-volume";
          spec.resouces.requests.storage = "256Gi";
        }];
        containers = [{
          name = "mongod";
          resources = {
            limits = { cpu = 1; memory = "20Gi"; };
            requests = { cpu = "100m"; memory = "1Gi"; };
          };
        }];
      };
      replicaSetHorizons = [
        { external = "mongodb-0.guiduck-mongodb.svc.poketwo.io:27017"; }
        { external = "mongodb-1.guiduck-mongodb.svc.poketwo.io:27017"; }
        { external = "mongodb-2.guiduck-mongodb.svc.poketwo.io:27017"; }
      ];
    };

    resources.v1.Secret."guiduck-mongodb-user" = {
      type = "Opaque";
      stringData.password = "";
    };

    resources.v1.Service = builtins.listToAttrs (map
      (index: {
        name = "guiduck-mongodb-${index}-external";
        value = makeLoadBalancer index;
      }) [ "0" "1" "2" ]);

    resources."cilium.io/v2".CiliumNetworkPolicy.allow-external-ingress-to-mongodb.spec = {
      endpointSelector.matchLabels.app = "guiduck-mongodb-svc";
      ingress = [{ fromEntities = [ "all" ]; }];
    };
  };
}
