{ ... }:

{
  namespaces.poketwo = {
    resources = {
      "apps/v1".Deployment.imgen-rust.spec = {
        replicas = 8;
        selector.matchLabels.app = "imgen-rust";
        template = {
          metadata.labels.app = "imgen-rust";
          spec = {
            containers = [{
              name = "server";
              image = "ghcr.io/poketwo/imgen-rust:latest";
              ports = [{ containerPort = 8000; }];
              resources = {
                limits = { memory = "50Mi"; };
                requests = { memory = "10Mi"; cpu = "50m"; };
              };
            }];
            imagePullSecrets = [{ name = "ghcr-auth"; }];
            affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 100;
              podAffinityTerm = {
                labelSelector.matchLabels.app = "imgen-rust";
                topologyKey = "kubernetes.io/hostname";
              };
            }];
          };
        };
      };

      "networking.k8s.io/v1".Ingress.imgen-rust-ingress = {
        metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
        spec = {
          rules = [{
            host = "imgen.poketwo.io";
            http.paths = [{
              path = "/";
              pathType = "Prefix";
              backend.service = { name = "imgen-rust"; port.number = 8000; };
            }];
          }];
          tls = [{
            hosts = [ "imgen.poketwo.io" ];
            secretName = "imgen-rust-ingress-tls";
          }];
        };
      };

      v1.Service.imgen-rust = {
        metadata.annotations."service.kubernetes.io/topology-mode" = "auto";
        spec = {
          selector.app = "imgen-rust";
          ports = [{ port = 8000; }];
        };
      };
    };
  };

}
