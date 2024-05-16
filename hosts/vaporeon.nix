{ ... }:

{
  imports = [
    ../hardware/vaporeon.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "vaporeon";
    hostId = "af85f3ae";
  };

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };

  poketwo.network = {
    enable = true;
    interfaces = [ "enp193s0f0np0" "enp193s0f1np1" ];
    lastOctet = 128;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
