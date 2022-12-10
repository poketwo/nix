{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "eevee";
  services.kubernetes.node-ip = "100.87.88.39";
  system.stateVersion = "22.05";
}
