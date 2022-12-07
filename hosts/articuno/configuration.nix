{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/profiles/base.nix
    ../../common/profiles/kubernetes/server.nix
  ];

  networking.hostName = "articuno";
  system.stateVersion = "22.05";
}
