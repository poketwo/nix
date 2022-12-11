{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kubernetes;
in
{
  age.secrets.k3s-server-token.file = ../../secrets/k3s-server-token.age;
  age.secrets.k3s-agent-token.file = ../../secrets/k3s-agent-token.age;

  swapDevices = lib.mkForce [ ];
  environment.systemPackages = [ pkgs.k3s ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--token-file=${config.age.secrets.k3s-server-token.path}"
      "--agent-token-file=${config.age.secrets.k3s-agent-token.path}"
      "--tls-san=control-plane.poketwo.io"
      "--node-taint=CriticalAddonsOnly=true:NoExecute"
      "--disable=servicelb"
      "--disable=traefik"
      "--disable=local-storage"
      "--flannel-backend=none"
      "--disable-kube-proxy"
      "--disable-network-policy"
      "--secrets-encryption"
    ];
  };

  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    # https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules

    allowedTCPPorts = [ 6443 2379 2380 10250 4240 ];
    allowedUDPPorts = [ 8472 ];
  };
}
