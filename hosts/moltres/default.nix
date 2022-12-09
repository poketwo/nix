{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/server.nix
  ];

  networking.hostName = "moltres";
  services.kubernetes.node-ip = "100.118.176.76";
  system.stateVersion = "22.05";
}
