{ config, pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "deino";
  system.stateVersion = "22.05";
}
