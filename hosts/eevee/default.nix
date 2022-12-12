{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/zfs.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "eevee";
  system.stateVersion = "22.05";
}
