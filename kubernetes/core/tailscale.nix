{ transpire, ... }:

{
  namespaces.tailscale = {
    helmReleases.tailscale-operator = {
      chart = transpire.fetchFromHelm {
        repo = "https://pkgs.tailscale.com/helmcharts";
        name = "tailscale-operator";
        version = "1.68.1";
        sha256 = "3j+DRDFF/iPvgGlyXFw2riniHwEb1diFKeMLb3Kp+HA=";
      };

      values = {
        operatorConfig = {
          image.repository = "ghcr.io/tailscale/k8s-operator";
          defaultTags = [ "tag:hfym-ds-operator" ];
          hostname = "hfym-ds-operator";
        };
        proxyConfig = {
          image.repository = "ghcr.io/tailscale/tailscale";
          defaultTags = "tag:hfym-ds";
        };
      };
    };

    resources.v1.Secret.operator-oauth = {
      type = "Opaque";
      stringData = {
        client_id = "";
        client_secret = "";
      };
    };

    resources."tailscale.com/v1alpha1".ProxyClass.prod.spec = {
      statefulSet.pod.tailscaleContainer.securityContext.privileged = true;
    };
  };
}
