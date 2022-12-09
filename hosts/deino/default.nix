{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "deino";
  services.kubernetes.node-ip = "100.114.243.119";
  system.stateVersion = "22.05";
}
