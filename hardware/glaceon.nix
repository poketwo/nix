{ ... }:

{
  imports = [
    ./presets/asus-rs500a-e12.nix
    ./presets/zfs-root.nix
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9D4D-56B0";
    fsType = "vfat";
  };
}
