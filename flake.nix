{
  description = "NixOS Configuration for Pokétwo";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/22.05;
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/v1.3.1;
    sops-nix.url = github:Mic92/sops-nix;
  };

  outputs = inputs@{ self, flake-utils-plus, sops-nix, ... }:
    flake-utils-plus.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];
      hostDefaults.modules = [ ./profiles/base.nix sops-nix.nixosModules.sops ];
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      hosts.articuno.modules = [ ./hosts/articuno.nix ];
      hosts.moltres.modules = [ ./hosts/moltres.nix ];
      hosts.zapdos.modules = [ ./hosts/zapdos.nix ];
    };
}
