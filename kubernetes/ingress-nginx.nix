{ transpire, ... }:

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
  };
}
