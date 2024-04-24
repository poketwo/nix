{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.poketwo.cloudflare-warp;

  cloudflareRootCert = pkgs.fetchurl {
    url = "https://developers.cloudflare.com/cloudflare-one/static/Cloudflare_CA.pem";
    sha256 = "sha256-7p2+Y657zy1TZAsOnZIKk+7haQ9myGTDukKdmupHVNU=";
  };
in
{
  options.poketwo.cloudflare-warp = {
    enable = mkEnableOption "Enable Cloudflare WARP configuration";
  };

  config = mkIf cfg.enable {
    age.secrets."cloudflare-warp-mdm.xml" = {
      file = ../../secrets/cloudflare-warp-mdm.xml.age;
      path = "/var/lib/cloudflare-warp/mdm.xml";
    };

    security.pki.certificateFiles = [ cloudflareRootCert ];
    environment.systemPackages = with pkgs; [ cloudflare-warp ];
    systemd.packages = with pkgs; [ cloudflare-warp ];
    systemd.services.warp-svc.wantedBy = [ "multi-user.target" ];
  };
}
