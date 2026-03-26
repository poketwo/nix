{ ... }:

{
  imports = [
    ./presets/gigabyte-r163-z30.nix
  ];

  disko.devices = {
    disk.boot = {
      type = "disk";
      device = "/dev/disk/by-path/pci-0000:05:00.0-nvme-1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "nixos";
            };
          };
        };
      };
    };

    zpool.nixos = {
      type = "zpool";
      options.cachefile = "none";
      rootFsOptions = {
        compression = "zstd";
        mountpoint = "legacy";
      };

      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        var = {
          type = "zfs_fs";
          mountpoint = "/var";
          options.mountpoint = "legacy";
        };
        home = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}
