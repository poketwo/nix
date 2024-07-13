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

  boot.kernelModules = [ "ceph" "br_netfilter" "ip6_tables" "ip6table_mangle" "ip6table_raw" "ip6table_filter" ];
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
      "--kubelet-arg=eviction-hard=memory.available<500m,nodefs.available<10%"
      "--kubelet-arg=kube-reserved=cpu=100m,memory=200m,ephemeral-storage=1Gi,pid=1000"
      "--kubelet-arg=system-reserved=cpu=100m,memory=200m,ephemeral-storage=1Gi,pid=1000"
      "--kubelet-arg=reserved-cpus=0"
      "--cluster-cidr=10.42.0.0/16,fde8:9036:df25::/56 --service-cidr=10.43.0.0/16,fd0a:5a2f:1807::/112"
    ];
  };

  networking.firewall = {
    # https://docs.k3s.io/installation/requirements#networking
    # https://docs.cilium.io/en/v1.11/operations/system_requirements/#firewall-rules
    # https://metallb.universe.tf/#requirements

    allowedTCPPorts = [ 6443 2379 2380 10250 4240 4244 7946 ];
    allowedUDPPorts = [ 8472 7946 ];
  };
}
