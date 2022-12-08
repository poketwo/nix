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
    swapDevices = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.k3s ];
    age.secrets.k3s-server-token.file = ../../secrets/k3s-server-token.age;

    services.k3s = {
      enable = true;
      role = "agent";
      tokenFile = config.age.secrets.k3s-server-token.path;
      serverAddr = "https://control-plane.poketwo.io:6443";
      extraFlags = (optionalString (cfg.node-ip != null) "--node-ip=${cfg.node-ip}");
    };
  };
}
