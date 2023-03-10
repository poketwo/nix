{
  description = "NixOS Configuration for Pokétwo";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/22.11;
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

      hosts.articuno.modules = [ ./hosts/articuno ];
      hosts.moltres.modules = [ ./hosts/moltres ];
      hosts.zapdos.modules = [ ./hosts/zapdos ];

      hosts.abra.modules = [ ./hosts/abra ];
      hosts.blissey.modules = [ ./hosts/blissey ];
      hosts.corsola.modules = [ ./hosts/corsola ];
      hosts.deino.modules = [ ./hosts/deino ];
      hosts.eevee.modules = [ ./hosts/eevee ];

      hosts.pichu.modules = [ ./hosts/pichu ];
    };
}
