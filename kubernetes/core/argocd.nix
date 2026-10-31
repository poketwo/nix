{ transpire, ... }:

{
  namespaces.argocd = {
    helmReleases.argocd = {
      chart = transpire.fetchFromHelm {
        repo = "https://argoproj.github.io/argo-helm";
        name = "argo-cd";
        version = "10.2.2";
        sha256 = "U89WH52NShxpzXivk+O5cC6nSs+eGBHQ0AY+ICSN+Sc=";
      };

      values = {
        global.domain = "argocd.hfym.co";
        # chart 10 creates NetworkPolicies by default; keep the namespace as it was
        global.networkPolicy.create = false;
        redis-ha.enabled = true;

        controller = {
          replicas = 1;
          metrics.enabled = true;
        };

        server = {
          replicas = 2;
          ingress = {
            enabled = true;
            tls = true;
            annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
          };
        };

        configs = {
          cm = {
            "resource.exclusions" = ''
              - apiGroups:
                - velero.io
                kinds:
                - Backup
            '';
            "resource.customizations.ignoreDifferences.admissionregistration.k8s.io_MutatingWebhookConfiguration" = ''
              jqPathExpressions:
              - .webhooks[]?.clientConfig.caBundle
            '';
            "resource.customizations.ignoreDifferences.apiextensions.k8s.io_CustomResourceDefinition" = ''
              jqPathExpressions:
              - .spec.conversion.webhook.clientConfig.caBundle
            '';
          };
          params = {
            "server.insecure" = true;
          };
        };
      };
    };
  };
}
