{ pkgs, lib, inputs, ... }:

{
  nix = {
    channel.enable = false;
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    settings = {
      experimental-features = "nix-command flakes";
      nix-path = lib.mapAttrsToList (name: _: "${name}=flake:${name}") inputs;
    };
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  nixpkgs.flake.setNixPath = true;

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

  networking = {
    useNetworkd = true;
    nameservers = [ "2606:4700:4700::1111" "2606:4700:4700::1001" "1.1.1.1" "1.0.0.1" ];
    nftables.enable = true;
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

  systemd.services.nix-remove-profiles = {
    description = "Remove old NixOS generations but leave store cleanup to nix.gc";
    script = ''
      keepGenerations=5
      profile="/nix/var/nix/profiles/system"

      to_delete=$(nix-env --list-generations --profile "$profile" | awk '{print $1}' | head -n -$keepGenerations)

      if [ -n "$to_delete" ]; then
        to_delete=$(echo "$to_delete" | tr '\n' ' ')
        nix-env --delete-generations $to_delete --profile "$profile"
      fi
    '';
    serviceConfig = {
      Environment = "PATH=/run/current-system/sw/bin";
      Type = "oneshot";
    };
  };

  systemd.timers.nix-remove-profiles = {
    description = "Run NixOS profile cleanup periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
