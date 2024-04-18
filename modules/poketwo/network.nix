{ lib, config, ... }:

with lib;
let
  cfg = config.poketwo.network;

  bondNetworks = listToAttrs (map
    (interface: {
      name = "30-${interface}";
      value = {
        matchConfig.Name = interface;
        networkConfig.Bond = "bond0";
      };
    })
    cfg.interfaces);
in
{
  options.poketwo.network = {
    enable = mkEnableOption "Enable network configuration";
    interfaces = mkOption {
      type = types.nonEmptyListOf types.str;
      description = "Names of the network interfaces";
    };
    lastOctet = mkOption {
      type = types.int;
      description = "Last octet of the IP address";
    };
  };

  config = mkIf cfg.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
      firewall.enable = false;
      nameservers = [ "1.1.1.1" "1.0.0.1" ];
    };

    systemd.network = {
      enable = true;

      netdevs."10-bond0" = {
        netdevConfig = {
          Name = "bond0";
          Kind = "bond";
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer3+4";
          MIIMonitorSec = "100ms";
          LACPTransmitRate = "fast";
        };
      };

      networks = bondNetworks // {
        "40-bond0" = {
          matchConfig.Name = "bond0";
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
  };
}
