{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/profiles/base.nix
  ];

  networking.hostName = "moltres";
  system.stateVersion = "22.05";
}
