{ lib, config, pkgs, ... }:

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
    # Host-side egress probes, scraped by Alloy on 9115 (firewall rule in
    # kubernetes.nix): native IPv4/IPv6 and NAT64 through this host's Jool.
    # See kubernetes/monitoring/alloy.nix for the targets.
    services.prometheus.exporters.blackbox = {
      enable = true;
      listenAddress = "[::]";
      configFile = pkgs.writeText "blackbox.yml" (builtins.toJSON {
        modules = {
          tcp4 = { prober = "tcp"; timeout = "5s"; tcp = { preferred_ip_protocol = "ip4"; ip_protocol_fallback = false; }; };
          tcp6 = { prober = "tcp"; timeout = "5s"; tcp = { preferred_ip_protocol = "ip6"; ip_protocol_fallback = false; }; };
          icmp4 = { prober = "icmp"; timeout = "5s"; icmp = { preferred_ip_protocol = "ip4"; ip_protocol_fallback = false; }; };
          icmp6 = { prober = "icmp"; timeout = "5s"; icmp = { preferred_ip_protocol = "ip6"; ip_protocol_fallback = false; }; };
        };
      });
    };

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
            { Gateway = "23.135.200.1"; }
            { Gateway = "2606:c2c0::1"; }
          ];
          domains = [ ];
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };

    # Proxy NDP for the Kubernetes pod CIDR so upstream router can reach pod IPs
    services.ndppd = {
      enable = true;
      proxies.inet0.rules."2606:c2c0:5:1:${toString cfg.lastOctet}::/80" = {
        method = "static";
      };
    };

    # ndppd needs inet0 to be up before it can bind; the upstream module only
    # sets After=network-pre.target which fires before interfaces are configured.
    systemd.services.ndppd = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
