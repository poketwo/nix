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
        operatorConfig.defaultTags = [ "tag:hfym-ds-operator" ];
        proxyConfig.defaultTags = "tag:hfym-ds";
      };
    };

    resources.v1.Secret.operator-oauth = {
      type = "Opaque";
      stringData = {
        client_id = "";
        client_secret = "";
      };
    };
  };
}
