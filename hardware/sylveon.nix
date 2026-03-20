{ ... }:

{
  imports = [
    ./presets/supermicro-1015cs-tnr.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12208078491427551280";
    fsType = "vfat";
  };
}
