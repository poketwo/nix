{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kubernetes;
in
{
  options.services.kubernetes = {
    node-ip = mkOption {
      description = "k3s node-ip";
      default = null;
      type = types.str;
    };
  };

  config = {
    age.secrets.k3s-agent-token.file = ../../secrets/k3s-server-token.age;

    swapDevices = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.k3s ];

    services.k3s = {
      enable = true;
      role = "agent";
      extraFlags = toString [
        (optionalString (cfg.node-ip != null) "--node-ip=${cfg.node-ip}")
        "--server=https://control-plane.poketwo.io:6443"
        "--token-file=${config.age.secrets.k3s-agent-token.path}"
      ];
    };
  };
}
