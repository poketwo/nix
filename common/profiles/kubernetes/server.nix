{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.k3s ];

  services.k3s = {
    enable = true;
    role = "server";
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
