{ ... }:

{
  imports = [
    ./presets/supermicro-1015cs-tnr.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9D5D-F4F6";
    fsType = "vfat";
  };
}
