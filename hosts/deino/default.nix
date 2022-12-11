{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "deino";
  system.stateVersion = "22.05";
}
