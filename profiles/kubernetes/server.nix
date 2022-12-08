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
    environment.systemPackages = [ pkgs.k3s ];
    age.secrets.k3s-server-token.file = ../../secrets/k3s-server-token.age;

    services.k3s = {
      enable = true;
      role = "server";
      tokenFile = config.age.secrets.k3s-server-token.path;
      extraFlags = toString [
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
        (optionalString apiserver-only "--disable-etcd")
        (optionalString apiserver-only "--disable-controller-manager")
        (optionalString apiserver-only "--disable-scheduler")
      ];
    };
  };
}
