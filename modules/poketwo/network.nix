{ lib, config, ... }:

let
  cfg = config.poketwo.network;

  bondNetworks = lib.listToAttrs (map
    (interface: {
      name = "30-${interface}";
      value = {
        matchConfig.Name = interface;
        networkConfig.Bond = "inet0";
      };
    })
    cfg.interfaces);
in
{
  options.poketwo.network = with lib; {
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

  config = lib.mkIf cfg.enable {
    networking = {
      useDHCP = false;
      useNetworkd = true;
    };

    systemd.network = {
      enable = true;

      netdevs."10-inet0" = {
        netdevConfig = {
          Name = "inet0";
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
        "40-inet0" = {
          matchConfig.Name = "inet0";
          address = [
            "23.135.200.${toString cfg.lastOctet}/24"
            "2606:c2c0:5::1:${toString cfg.lastOctet}/32"
          ];
          routes = [
            { routeConfig.Gateway = "23.135.200.1"; }
            { routeConfig.Gateway = "2606:c2c0::1"; }
          ];
          domains = [ ];
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };
  };
}
