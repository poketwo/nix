{ lib, config, ... }:

let
  cfg = config.poketwo.auth;
in
{
  options.poketwo.auth = {
    enable = lib.mkEnableOption "Enable auth configuration";
  };

  config = lib.mkIf cfg.enable {
    users.users.oliver = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A oliver.ni@gmail.com" ];
    };

    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
      }
    ];
  };
}
