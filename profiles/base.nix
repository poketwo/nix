{ pkgs, lib, ... }:

{
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];

  poketwo = {
    auth.enable = lib.mkDefault true;
    locale.enable = lib.mkDefault true;
    nat64.enable = lib.mkDefault true;
    shell.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
  };

  boot = {
    supportedFilesystems.zfs = true;
    loader.efi.canTouchEfiVariables = true;
  };

  services = {
    openssh = {
      enable = true;
      settings.X11Forwarding = true;
    };

    fwupd.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [ vim htop dig wget curl ];

    etc."nixos/configuration.nix".text = ''
      {}: builtins.abort "This machine is not managed by /etc/nixos. Please use colmena instead."
    '';
  };
}
