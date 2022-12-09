{ ... }:

{
  imports = [
    ./hardware.nix
    ../profiles/kubernetes/server.nix
  ];

  networking.hostName = "zapdos";
  services.kubernetes.node-ip = "100.72.150.37";
  system.stateVersion = "22.05";
}
