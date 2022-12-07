{ ... }:

{
  imports = [
    ../../common/hardware/hetzner-cloud.nix
    ../../common/profiles/kubernetes/server.nix
  ];

  networking.hostName = "articuno";
  system.stateVersion = "22.05";
}
