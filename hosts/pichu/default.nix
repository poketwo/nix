{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/exit-nide.nix
  ];

  networking.hostName = "pichu";
  system.stateVersion = "22.05";

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
}