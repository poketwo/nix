{ ... }:

{
  imports = [
    ../hardware/sylveon.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "sylveon";
    hostId = "23c2eb51";
  };

  poketwo.network = {
    enable = true;
    interfaces = [ "enp225s0f0np0" "enp225s0f1np1" ];
    lastOctet = 132;
  };

  poketwo.kubernetes.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
