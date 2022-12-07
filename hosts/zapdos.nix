{ ... }:

{
  imports = [
    ../hardware/hetzner-cloud.nix
    ../profiles/kubernetes/server.nix
  ];

  networking.hostName = "zapdos";
  system.stateVersion = "22.05";
}
