{ ... }:

{
  imports = [
    ./presets/gigabyte-r163-z30.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E971-B51B";
    fsType = "vfat";
  };
}
