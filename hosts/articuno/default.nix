{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/server.nix
  ];

  networking.hostName = "articuno";
  system.stateVersion = "22.05";
}
