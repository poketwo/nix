{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../common/profiles/base.nix
  ];

  networking.hostName = "articuno";
}
