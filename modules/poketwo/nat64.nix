{ pkgs, lib, config, ... }:

let
  cfg = config.poketwo.nat64;

  ip = "${pkgs.iproute2}/bin/ip";

  # This sets up Jool in a separate network namespace, and configures the NAT64
  # prefix 64:ff9b::/96 to be routed through the Jool instance. This is based on
  # the tutorial at https://www.jool.mx/en/node-based-translation.html, though
  # that page sets up SIIT rather than NAT64.

  setupJool = pkgs.writers.writeBash "setup-jool" ''
    # Add a namespace for Jool and a veth pair to connect it to the world
    ${ip} netns add ${cfg.netNsName}
    ${ip} link add name to_jool type veth peer name to_world netns ${cfg.netNsName}

    # Configure IP addresses in global namespace
    ${ip} link set dev to_jool up
    ${ip} -4 address add dev to_jool 10.100.64.1/30
    ${ip} -6 address add dev to_jool fd64:cac4:1daa::1/64

    # Configure IP addresses in Jool namespace
    ${ip} netns exec ${cfg.netNsName} ${ip} link set dev to_world up
    ${ip} netns exec ${cfg.netNsName} ${ip} -4 address add dev to_world 10.100.64.2/30
    ${ip} netns exec ${cfg.netNsName} ${ip} -6 address add dev to_world fd64:cac4:1daa::2/64

    # Route Jool's IPv4 traffic to the world (this requires NAT)
    ${ip} netns exec ${cfg.netNsName} ${ip} -4 route add default via 10.100.64.1

    # Route the NAT64 prefix to Jool
    ${ip} -6 route add 64:ff9b::/96 dev to_jool via fd64:cac4:1daa::2
  '';

  cleanupJool = pkgs.writers.writeBash "cleanup-jool" ''
    ${ip} netns del jool
  '';
in
{
  options.poketwo.nat64 = {
    enable = lib.mkEnableOption "Enable host-based NAT64 configuration";
    netNsName = lib.mkOption {
      type = lib.types.str;
      default = "jool";
      description = "Name of the network namespace to use for Jool";
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      nameservers = lib.mkForce [ "2606:4700:4700::64" "2606:4700:4700::6400" "1.1.1.1" "1.1.1.1" ];

      jool = {
        enable = true;
        nat64.default.framework = "netfilter";
      };

      nat = {
        enable = true;
        internalInterfaces = [ "to_jool" ];
        externalInterface = "inet0";
      };
    };

    systemd.services = {
      jool-nat64-default-netns.serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = setupJool;
        ExecStopPost = cleanupJool;
      };

      jool-nat64-default = {
        bindsTo = [ "jool-nat64-default-netns.service" ];
        after = [ "jool-nat64-default-netns.service" ];
        serviceConfig.NetworkNamespacePath = "/var/run/netns/jool";
      };
    };
  };
}
