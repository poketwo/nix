{ config, pkgs, lib, ... }:

let
  kubePkgs = with pkgs; [ kubernetes cri-o ethtool socat conntrack-tools ];
in
{
  swapDevices = lib.mkForce [ ];
  boot.kernelModules = [ "br_netfilter" "overlay" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
  };

  environment.systemPackages = kubePkgs;

  environment.etc = {
    "cni/net.d".enable = false; # https://github.com/NixOS/nixpkgs/issues/130804#issuecomment-1241361630
    "kubernetes/kubeadm.yaml".source = ./kubeadm.yaml;
  };

  virtualisation.cri-o = {
    enable = true;
    pauseImage = "registry.k8s.io/pause:3.6";
    pauseCommand = "/pause";
  };

  systemd.services.kubelet = {
    description = "Kubernetes Kubelet Service";
    wantedBy = [ "multi-user.target" ];
    path = kubePkgs;

    serviceConfig = {
      StateDirectory = "kubelet";
      ConfiguratonDirectory = "kubernetes";
      EnvironmentFile = "-/var/lib/kubelet/kubeadm-flags.env";
      Restart = "always";
      RestartSec = "1000ms";
      ExecStart = "${pkgs.kubernetes}/bin/kubelet --kubeconfig=/etc/kubernetes/kubelet.conf $KUBELET_KUBEADM_ARGS";
    };
  };
}
