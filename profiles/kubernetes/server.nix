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
        (optionalString (cfg.node-ip != null) "--node-ip=${cfg.node-ip}")
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
  };
}
