{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/profiles/base.nix
  ];

  networking.hostName = "articuno";
  system.stateVersion = "22.05";
}
