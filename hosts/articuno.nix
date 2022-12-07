{ ... }:

{
  imports = [
    ../hardware/hetzner-cloud.nix
    ../profiles/kubernetes/server.nix
  ];

  networking.hostName = "articuno";
  services.kubernetes.node-ip = "100.100.209.57";
  system.stateVersion = "22.05";
}
