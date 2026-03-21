{ lib, config, ... }:

let
  cfg = config.poketwo.deploy;
  deploy-user = "deploy";
in
{
  options.poketwo.deploy = {
    enable = lib.mkEnableOption "Enable dedicated deploy user for deploy-rs";
  };

  config = lib.mkIf cfg.enable {
    users.users.${deploy-user} = {
      isNormalUser = true;
      createHome = false;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A oliver.ni@gmail.com"
      ];
    };

    nix.settings.trusted-users = [ deploy-user ];

    security.sudo.extraRules = [
      {
        users = [ deploy-user ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nix-store --no-gc-warning --realise /nix/store/*";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-env --profile /nix/var/nix/profiles/system --set /nix/store/*";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/nix/store/*/bin/switch-to-configuration *";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
