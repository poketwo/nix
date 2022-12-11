{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/server.nix
  ];

  networking.hostName = "moltres";
  system.stateVersion = "22.05";
}
