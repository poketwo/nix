{ ... }:

{
  imports = [
    ./presets/linode.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3DB6-3D66";
    fsType = "vfat";
  };
}
