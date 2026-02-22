{ ... }:

{
  imports = [
    ./presets/gigabyte-r163-z30.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A3CB-91E3";
    fsType = "vfat";
  };
}
