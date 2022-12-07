{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/profiles/base.nix
  ];

  networking.hostName = "zapdos";
  system.stateVersion = "22.05";
}
