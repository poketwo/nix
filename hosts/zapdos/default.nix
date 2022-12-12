{ ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/kubernetes/server.nix
  ];

  networking.hostName = "zapdos";
  system.stateVersion = "22.05";

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
}
