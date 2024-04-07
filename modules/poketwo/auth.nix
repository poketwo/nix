{ lib, config, ... }:

with lib;
let
  cfg = config.poketwo.auth;
in
{
  options.poketwo.auth = {
    enable = mkEnableOption "Enable auth configuration";
  };

  config.users.users = mkIf (cfg.enable) {
    oliver = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A oliver.ni@gmail.com" ];
    };
  };
}
