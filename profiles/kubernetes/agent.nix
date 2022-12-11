{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kubernetes;
in
{
  age.secrets.k3s-agent-token.file = ../../secrets/k3s-agent-token.age;

  swapDevices = lib.mkForce [ ];
  environment.systemPackages = [ pkgs.k3s ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
  };

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://control-plane.poketwo.io:6443";
    tokenFile = config.age.secrets.k3s-agent-token.path;
  };

  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    # https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules

    allowedTCPPorts = [ 10250 4240 ];
    allowedUDPPorts = [ 8472 ];
  };
}
