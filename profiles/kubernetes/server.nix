{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.k3s ];
  sops.secrets.k3s-server-token.sopsFile = ../../secrets/k3s.yaml;

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets.k3s-server-token.path;
    serverAddr = "https://control-plane.poketwo.io:6443";
    extraFlags = toString [
      "--tls-san=control-plane.poketwo.io"
      "--node-taint=CriticalAddonsOnly=true:NoExecute"
      "--disable=servicelb"
      "--disable=traefik"
      "--disable=local-storage"
      "--flannel-backend=none"
      "--disable-network-policy"
      "--secrets-encryption"
    ];
  };
}
