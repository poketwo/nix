{
  description = "NixOS Configuration for Pokétwo";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/22.05;
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus/v1.3.1;
    agenix.url = "github:ryantm/agenix/0.13.0";
  };

  outputs = inputs@{ self, flake-utils-plus, agenix, ... }:
    flake-utils-plus.lib.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];
      hostDefaults.modules = [
        ./profiles/base.nix
        agenix.nixosModule
      ];

      hosts.articuno.modules = [ ./hosts/articuno.nix ];
      hosts.moltres.modules = [ ./hosts/moltres.nix ];
      hosts.zapdos.modules = [ ./hosts/zapdos.nix ];
    };
}
