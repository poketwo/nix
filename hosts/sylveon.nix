{ ... }:

{
  imports = [
    ../hardware/sylveon.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "sylveon";
    hostId = "TODO"; # TODO: generate with `head -c 4 /dev/urandom | od -A none -t x4 | tr -d ' '`
  };

  poketwo.network = {
    enable = true;
    interfaces = [ "TODO" ]; # TODO: fill in network interface names
    lastOctet = 132; # TODO: confirm
  };

  poketwo.kubernetes.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
