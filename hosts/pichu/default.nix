{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/exit-node.nix
  ];

  networking.hostName = "pichu";
  system.stateVersion = "22.05";

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
}
