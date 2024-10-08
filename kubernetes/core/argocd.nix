{ transpire, ... }:

{
  namespaces.argocd = {
    helmReleases.argocd = {
      chart = transpire.fetchFromHelm {
        repo = "https://argoproj.github.io/argo-helm";
        name = "argo-cd";
        version = "7.1.3";
        sha256 = "YUnyW4jX1Cp+9ob6Jf04zxKEwmT+pZN9ztIGeaa03JU=";
      };

      values = {
        global.domain = "argocd.hfym.co";
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
