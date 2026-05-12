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
          # Must be a string, not a list — chart template doesn't join it
          # https://github.com/tailscale/tailscale/issues/16773
          defaultTags = "tag:hfym-ds";
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

    # Subnet router for Kubernetes service + MetalLB CIDRs
    resources."tailscale.com/v1alpha1".Connector.k8s-subnet-router.spec = {
      subnetRouter = {
        advertiseRoutes = [
          "2606:c2c0:5:1:2::/112" # Service CIDR
          "2606:c2c0:5:1:3::/112" # MetalLB CIDR
          "2606:c2c0:5:1:128::/80" # Pod CIDR (vaporeon)
          "2606:c2c0:5:1:129::/80" # Pod CIDR (jolteon)
          "2606:c2c0:5:1:130::/80" # Pod CIDR (flareon)
          "2606:c2c0:5:1:131::/80" # Pod CIDR (glaceon)
          "2606:c2c0:5:1:132::/80" # Pod CIDR (sylveon)
        ];
      };
    };
  };
}
