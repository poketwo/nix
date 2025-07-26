{ ... }:

{
  namespaces.poketwo = {
    resources = {
      "apps/v1".Deployment.image-server.spec = {
        replicas = 30;
        selector.matchLabels.app = "image-server";
        template = {
          metadata.labels.app = "image-server";
          spec = {
            containers = [{
              name = "server";
              image = "ghcr.io/poketwo/image-server:latest";
              ports = [{ containerPort = 8080; }];
              resources = {
                limits = { memory = "1.5Gi"; };
                requests = { memory = "1.5Gi"; cpu = "100m"; };
              };
              readinessProbe = {
                httpGet = { path = "/"; port = 8080; };
                initialDelaySeconds = 5;
                periodSeconds = 5;
              };
            }];
            imagePullSecrets = [{ name = "ghcr-auth"; }];
            affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100;
              podAffinityTerm = {
                labelSelector.matchLabels.app = "image-server";
                topologyKey = "kubernetes.io/hostname";
              };
            }];
          };
        };
      };

      "networking.k8s.io/v1".Ingress.image-server-ingress = {
        metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
        spec = {
          rules = [{
            host = "server.poketwo.io";
            http.paths = [{
              path = "/";
              pathType = "Prefix";
              backend.service = { name = "image-server"; port.number = 80; };
            }];
          }];
          tls = [{
            hosts = [ "server.poketwo.io" ];
            secretName = "image-server-ingress-tls";
          }];
        };
      };

      v1.Service.image-server = {
        metadata.annotations."service.kubernetes.io/topology-mode" = "Auto";
        spec = {
          selector.app = "image-server";
          ports = [{ port = 80; targetPort = 8080; }];
        };
      };
    };
  };
}
