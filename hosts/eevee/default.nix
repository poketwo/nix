{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "eevee";
  system.stateVersion = "22.05";
}
