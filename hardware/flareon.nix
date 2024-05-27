{ ... }:

{
  imports = [
    ./presets/gigabyte-r163-z30.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E999-4B47";
    fsType = "vfat";
  };
}
