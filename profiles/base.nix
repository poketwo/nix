{ lib, pkgs, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];

  poketwo = {
    auth.enable = lib.mkDefault true;
    locale.enable = lib.mkDefault true;
    network.enable = lib.mkDefault false;
    shell.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services = {
    openssh.enable = true;
    fwupd.enable = true;
  };

  environment.etc."nixos/configuration.nix".text = ''
    {}: builtins.abort "This machine is not managed by /etc/nixos. Please use colmena instead."
  '';
}
