{ config, pkgs, ... }:

{
  boot.cleanTmpDir = true;
  zramSwap.enable = true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  security.sudo.wheelNeedsPassword = false;
  users.users.oliver = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A oliver.ni@gmail.com"
    ];
  };

  environment.systemPackages = with pkgs; [
    wget
    vim
    git
    tmux

    tailscale
  ];

  services = {
    openssh.enable = true;
    tailscale.enable = true;
  };

  networking.firewall.checkReversePath = "loose";
}
