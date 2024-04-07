{ config, pkgs, ... }:

{
  imports = [
    ../hardware/gigabyte-r163-z30-3.nix
  ];

  networking.hostName = "turtwig";

  fileSystems = {
    "/".options = [ "compress=zstd" ];
    "/home".options = [ "compress=zstd" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
  };

  poketwo.network = {
    enable = true;
    interface = "enp193s0f0np0";
    lastOctet = 130;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
