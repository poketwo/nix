{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/server.nix
    ../../profiles/exit-node.nix
  ];

  networking.hostName = "articuno";
  system.stateVersion = "22.05";

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
}
