{ ... }:

{
  imports = [
    ../../common/hardware/hetzner-cloud.nix
  ];

  networking.hostName = "moltres";
  system.stateVersion = "22.05";
}
