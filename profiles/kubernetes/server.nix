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

    apiserver-only = mkOption {
      description = "k8s apiserver only";
      default = false;
      type = types.bool;
    };
  };

  config = {
    age.secrets.k3s-server-token.file = ../../secrets/k3s-server-token.age;
    age.secrets.k3s-agent-token.file = ../../secrets/k3s-agent-token.age;

    swapDevices = lib.mkForce [ ];
    environment.systemPackages = [ pkgs.k3s ];

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
        (optionalString (cfg.node-ip != null) "--node-ip=${cfg.node-ip}")
        (optionalString cfg.apiserver-only "--disable-etcd")
        (optionalString cfg.apiserver-only "--disable-controller-manager")
        (optionalString cfg.apiserver-only "--disable-scheduler")
      ];
    };
  };
}
