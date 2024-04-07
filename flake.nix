{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # ========================
      # NixOS Host Configuration
      # ========================

      # Put modules common to all hosts here.
      commonModules = [
        ./modules/poketwo/auth.nix
        ./modules/poketwo/environment.nix
        ./modules/poketwo/locale.nix
        ./modules/poketwo/network.nix
        ./profiles/base.nix
      ];

      # Put modules for specific hosts here.
      hosts = {
        turtwig = [ ./hosts/1-turtwig.nix ];
        chimchar = [ ./hosts/2-chimchar.nix ];
        piplup = [ ./hosts/3-piplup.nix ];
      };

      # =====================
      # Colmena Configuration
      # =====================

      pkgs-x86_64-linux = import nixpkgs {
        system = "x86_64-linux";
        config = { allowUnfree = true; };
      };

      colmena = builtins.mapAttrs
        (host: modules: {
          imports = commonModules ++ modules;
          deployment.buildOnTarget = true;
          deployment.targetUser = "oliver";
          deployment.allowLocalDeployment = true;
        })
        hosts;

      colmenaOutputs = {
        colmena = colmena // {
          meta = { nixpkgs = pkgs-x86_64-linux; };
        };
      };

      # =======================
      # Dev Shell Configuration
      # =======================

      devShellOutputs = flake-utils.lib.eachDefaultSystem
        (system:
          let pkgs = import nixpkgs { inherit system; }; in {
            devShells.default = pkgs.mkShell {
              packages = [ pkgs.colmena ];
            };
          }
        );
    in
    colmenaOutputs // devShellOutputs;
}
