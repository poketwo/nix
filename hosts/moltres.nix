{ ... }:

{
  imports = [
    ../hardware/hetzner-cloud.nix
    ../profiles/kubernetes/server.nix
  ];

  networking.hostName = "moltres";
  system.stateVersion = "22.05";
}
