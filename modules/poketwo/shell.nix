{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.poketwo.shell;
in
{
  options.poketwo.shell = {
    enable = mkEnableOption "Enable shell configuration";
  };

  config = mkIf (cfg.enable) {
    environment = {
      enableAllTerminfo = true;
      etc."p10k.zsh".source = ./shell/p10k.zsh;
      systemPackages = with pkgs; [
        zsh
        zsh-powerlevel10k
      ];
    };

    users.defaultUserShell = pkgs.zsh;

    programs = {
      zsh = {
        enable = true;
        shellInit = ''
          if [[ ! -f ~/.zshrc ]]; then
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
            source /etc/p10k.zsh
          fi
          zsh-newuser-install() { :; }
        '';
      };
    };
  };
}
