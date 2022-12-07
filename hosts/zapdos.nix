{ ... }:

{
  imports = [
    ../hardware/hetzner-cloud.nix
  ];

  networking.hostName = "zapdos";
  system.stateVersion = "22.05";
}
