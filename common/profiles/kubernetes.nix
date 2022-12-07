{ config, pkgs, ... }:

{
  swapDevices = lib.mkForce [ ];
  environment.systemPackages = with pkgs; [
    kubernetes
    cri-o
  ];
}
