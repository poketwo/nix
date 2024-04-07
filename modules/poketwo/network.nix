{ lib, config, ... }:

with lib;
let
  cfg = config.poketwo.network;
in
{
  options.poketwo.network = {
    enable = mkEnableOption "Enable network configuration";
    interface = mkOption {
      type = types.str;
      description = "Name of the network interface";
    };
    lastOctet = mkOption {
      type = types.int;
      description = "Last octet of the IP address";
    };
  };

  config = mkIf (cfg.enable) {
    networking = {
      useDHCP = false;
      useNetworkd = true;
      firewall.enable = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" ];
    };

    systemd.network = {
      enable = true;

      networks."10-wired" = {
        matchConfig.Name = cfg.interface;
        address = [
          "23.135.200.${toString cfg.lastOctet}/24"
          "2606:c2c0:0005::1:${toString cfg.lastOctet}/32"
        ];
        routes = [
          { routeConfig.Gateway = "23.135.200.1"; }
          { routeConfig.Gateway = "2606:c2c0::1"; }
        ];
        domains = [ "poketwo.io" ];
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
