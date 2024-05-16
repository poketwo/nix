{ ... }:

{
  fileSystems."/" = {
    device = "nixos/root";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "nixos/nix";
    fsType = "zfs";
  };

  fileSystems."/var" = {
    device = "nixos/var";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "nixos/home";
    fsType = "zfs";
  };
}
