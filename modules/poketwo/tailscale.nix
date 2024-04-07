{ lib, config, ... }:

with lib;
let
  cfg = config.poketwo.tailscale;
in
{
  options.poketwo.tailscale = {
    enable = mkEnableOption "Enable Tailscale configuration";
  };

  config = mkIf (cfg.enable) {
    age.secrets.tailscale-auth-key.file = ../../secrets/tailscale-auth-key.age;

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.age.secrets.tailscale-auth-key.path;
      extraUpFlags = [
        "--accept-dns"
        "--accept-routes"
        "--advertise-connector"
        "--advertise-exit-node"
        "--ssh"
      ];
    };
  };
}
