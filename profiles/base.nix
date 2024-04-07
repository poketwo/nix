{ lib, pkgs, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];

  poketwo = {
    auth.enable = lib.mkDefault true;
    environment.enable = lib.mkDefault true;
    locale.enable = lib.mkDefault true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services = {
    openssh.enable = true;
    fwupd.enable = true;
  };
}
