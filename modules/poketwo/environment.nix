{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.poketwo.environment;
in
{
  options.poketwo.environment = {
    enable = mkEnableOption "Enable environment configuration";
  };

  config = mkIf (cfg.enable) {
    environment = {
      enableAllTerminfo = true;
      etc."p10k.zsh".source = ./environment/p10k.zsh;
      systemPackages = with pkgs; [
        bash
        zsh
        fish
        xonsh
        zsh-powerlevel10k
      ];
    };

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
      fish.enable = true;
      xonsh.enable = true;
      nix-ld.enable = true;
    };

    services.envfs = {
      enable = true;
      extraFallbackPathCommands = ''
        ln -s ${pkgs.bash}/bin/bash $out/bash
        ln -s ${pkgs.zsh}/bin/zsh $out/zsh
        ln -s ${pkgs.fish}/bin/fish $out/fish
        ln -s ${pkgs.xonsh}/bin/xonsh $out/xonsh
      '';
    };
  };
}
