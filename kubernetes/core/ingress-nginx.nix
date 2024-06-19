{ transpire, ... }:

let
  cloudflareIPs = [
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];
in
{
  namespaces.ingress-nginx = {
    helmReleases.ingress-nginx = {
      chart = transpire.fetchFromHelm {
        repo = "https://kubernetes.github.io/ingress-nginx";
        name = "ingress-nginx";
        version = "4.10.1";
        sha256 = "BHRoXG5EtJdCGkzy52brAtEcMEZP+WkNtfBf+cwpNbs=";
      };

      values = {
        controller = {
          ingressClassResource.default = true;
          service = {
            labels."hfym.co/ingress-policy" = "cloudflare";
            ipFamilies = [ "IPv6" ];
            enableHttp = false;
            enableHttps = true;
          };
          metrics.enabled = true;
        };
      };
    };

    resources."cilium.io/v2".CiliumNetworkPolicy.allow-cloudflare-ingress.spec = {
      endpointSelector = { };
      ingress = [{ fromCIDR = cloudflareIPs; }];
    };
  };
}
