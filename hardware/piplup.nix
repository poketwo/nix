{ ... }:

{
  imports = [
    ./presets/linode.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3DC4-ED65";
    fsType = "vfat";
  };
}
