{ ... }:

{
  imports = [
    ./presets/linode.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/418A-A074";
    fsType = "vfat";
  };
}
