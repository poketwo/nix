{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.kubernetes;
in
{
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
    role = "agent";
    serverAddr = "https://birds.poketwo.io:6443";
    tokenFile = config.age.secrets.k3s-agent-token.path;
    extraFlags = toString [
      "--kubelet-arg=cpu-manager-policy=static"
      "--kubelet-arg=eviction-hard=memory.available<2Gi,nodefs.available<10%"
      "--kubelet-arg=kube-reserved=cpu=500m,memory=2Gi,ephemeral-storage=8Gi,pid=1000"
      "--kubelet-arg=system-reserved=cpu=500m,memory=2Gi,ephemeral-storage=8Gi,pid=1000"
      "--kubelet-arg=reserved-cpus=0"
    ];
  };

  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    # https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules
    # https://metallb.universe.tf

    allowedTCPPorts = [ 10250 4240 4244 7946 ];
    allowedUDPPorts = [ 8472 7946 ];
  };
}
