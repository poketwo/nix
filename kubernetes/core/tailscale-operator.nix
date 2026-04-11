{ transpire, ... }:

{
  namespaces.tailscale = {
    helmReleases.tailscale-operator = {
      chart = transpire.fetchFromHelm {
        repo = "https://pkgs.tailscale.com/helmcharts";
        name = "tailscale-operator";
        version = "1.96.5";
        sha256 = "Dh/fRXdA9z+TMfg7rzfKhKt5cRh6cDYPotP4hXvEpls=";
      };

      values = {
        operatorConfig = {
          defaultTags = [ "tag:hfym-ds-operator" ];
          hostname = "hfym-ds-operator";
        };
        proxyConfig = {
          defaultTags = [ "tag:hfym-ds" ];
        };
      };

      includeCRDs = true;
    };

    # OAuth credentials for the Tailscale operator (managed via Vault)
    resources.v1.Secret.operator-oauth = {
      type = "Opaque";
      stringData = {
        client_id = "";
        client_secret = "";
      };
    };

    # Subnet router for Kubernetes service CIDR
    resources."tailscale.com/v1alpha1".Connector.k8s-subnet-router.spec = {
      subnetRouter = {
        advertiseRoutes = [ "2606:c2c0:5:1:2::/112" ];
      };
    };
  };
}
