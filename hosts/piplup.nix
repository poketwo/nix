{ ... }:

{
  imports = [
    ../hardware/piplup.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    hostName = "piplup";
    hostId = "a4df40e7";
    usePredictableInterfaceNames = false;
  };

  systemd.network = {
    enable = true;
    links."10-inet0" = {
      matchConfig.OriginalName = "eth0";
      linkConfig.Name = "inet0";
    };
    networks."10-inet0" = {
      matchConfig.Name = "inet0";
      networkConfig.DHCP = "yes";
    };
  };

  poketwo.kubernetes.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
