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

  boot.kernelModules = [ "ceph" ];
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
    "vm.max_map_count" = 262144;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--https-listen-port=6443"
      "--token-file=${config.age.secrets.k3s-server-token.path}"
      "--agent-token-file=${config.age.secrets.k3s-agent-token.path}"
      "--tls-san=birds.poketwo.io"
      "--node-taint=CriticalAddonsOnly=true:NoExecute"
      "--disable=servicelb"
      "--disable=traefik"
      "--disable=local-storage"
      "--flannel-backend=none"
      "--disable-kube-proxy"
      "--disable-network-policy"
      "--secrets-encryption"
      "--kubelet-arg=cpu-manager-policy=static"
    ];
  };

  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    # https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules

    allowedTCPPorts = [ 6443 2379 2380 10250 4240 4244 ];
    allowedUDPPorts = [ 8472 ];
  };
}
