{ ... }:

{
  imports = [
    ../hardware/turtwig.nix
  ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    hostName = "turtwig";
    hostId = "0a29d5d3";
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
      address = [
        "50.116.4.187/24"
        "2600:3c01::f03c:94ff:fe23:6ecb/64"
      ];
      routes = [
        { routeConfig.Gateway = "50.116.4.1"; }
        { routeConfig.Gateway = "fe80::1"; }
      ];
      # Linode anti-spoofing drops packets from unknown source addresses,
      # so disable IPv6 privacy extensions and accept RAs even with forwarding.
      networkConfig.IPv6PrivacyExtensions = false;
      networkConfig.IPv6AcceptRA = "yes";
      domains = [ ];
      linkConfig.RequiredForOnline = "routable";
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
