{ lib, config, pkgs, ... }:

let
  cfg = config.poketwo.kubernetes;
  yaml = pkgs.formats.yaml { };

  separator = pkgs.writeText "separator.yaml" "\n---\n";

  initConfiguration = yaml.generate "kubeadm-init.yaml" {
    apiVersion = "kubeadm.k8s.io/v1beta3";
    kind = "InitConfiguration";
    localAPIEndpoint = {
      advertiseAddress = "::";
      bindPort = 443;
    };
    skipPhases = [ "addon/kube-proxy" ];
  };

  clusterConfiguration = yaml.generate "kubeadm-cluster.yaml" {
    apiVersion = "kubeadm.k8s.io/v1beta3";
    kind = "ClusterConfiguration";
    kubernetesVersion = "v1.30.0";
    clusterName = "hfym-ds";
    controlPlaneEndpoint = "ds.hfym.co";
    networking.serviceSubnet = "2606:c2c0:5:1:2::/108";
  };

  kubeadmYaml = pkgs.concatText "kubeadm.yaml" [
    initConfiguration
    separator
    clusterConfiguration
  ];
in
{
  options.poketwo.kubernetes = {
    enable = lib.mkEnableOption "Enable Kubernetes configuration";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "br_netfilter" ];

    environment = {
      systemPackages = with pkgs; [ kubernetes conntrack-tools ethtool iptables socat ];
      etc."kubernetes/kubeadm.yaml".source = kubeadmYaml;
    };

    virtualisation.cri-o = {
      enable = true;
      storageDriver = "zfs";
      runtime = "crun";
    };

    networking.firewall = {
      allowedTCPPorts = [
        # Kubernetes: https://kubernetes.io/docs/reference/networking/ports-and-protocols/
        443 # Kubernetes API server
        2379 # etcd client requests
        2380 # etcd peer communication
        10250 # Kubelet API
        10259 # kube-scheduler
        10257 # kube-controller-manager

        # Cilium: https://docs.cilium.io/en/v1.15/operations/system_requirements/
        4240 # cluster health checks
        4244 # Hubble server
        4245 # Hubble relay

        # MetalLB: https://metallb.universe.tf/#requirements
        7946
      ];

      allowedUDPPorts = [
        # # Cilium: https://docs.cilium.io/en/v1.15/operations/system_requirements/
        # 8472 # VXLAN overlay

        # MetalLB: https://metallb.universe.tf/#requirements
        7946 # L2 mode
      ];

      # NodePort services
      allowedTCPPortRanges = [{ from = 30000; to = 32767; }];
    };

    systemd.services.kubelet = {
      # Provided by basic kubelet.service
      # https://github.com/kubernetes/release/blob/cd53840/cmd/krel/templates/latest/kubelet/kubelet.service

      description = "kubelet: The Kubernetes Node Agent";
      documentation = [ "https://kubernetes.io/docs/" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Restart = "always";
        StartLimitInterval = 0;
        RestartSec = 10;

        # Provided by kubeadm drop-in file
        # https://github.com/kubernetes/release/blob/cd53840/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf
        EnvironmentFile = "-/var/lib/kubelet/kubeadm-flags.env";
        ExecStart = ''
          ${pkgs.kubernetes}/bin/kubelet \
            --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
            --kubeconfig=/etc/kubernetes/kubelet.conf \
            --config=/var/lib/kubelet/config.yaml \
            --resolv-conf=/etc/resolv.conf \
            --node-ip=:: \
            $KUBELET_KUBEADM_ARGS
        '';
      };

      wantedBy = [ "multi-user.target" ];
    };

    # Kubernetes is incompatible with swap
    swapDevices = lib.mkForce [ ];
  };
}
