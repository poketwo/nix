{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../profiles/zfs.nix
    ../../profiles/kubernetes/agent.nix
  ];

  networking.hostName = "eevee";
  networking.hostId = "061bd7ea";
  system.stateVersion = "22.05";

  fileSystems."/" = {
    device = "/dev/nvme0n1p1";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" ];
  };

  fileSystems."/home" = {
    device = "/dev/nvme0n1p1";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" ];
  };

  fileSystems."/nix" = {
    device = "/dev/nvme0n1p1";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/nvme0n1p4";
    fsType = "vfat";
  };

  boot.zfs.extraPools = [ "mongo" ];

  fileSystems."/mongo" = {
    device = "/dev/zvol/mongo/mongo";
    fsType = "xfs";
  };
}
