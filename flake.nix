{
  description = "NixOS desktop configuration for the Open Computing Facility";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, agenix }:
    let
      # ========================
      # NixOS Host Configuration
      # ========================

      # Put modules common to all hosts here.
      commonModules = [
        agenix.nixosModules.default
        ./modules/poketwo/auth.nix
        ./modules/poketwo/cloudflare-warp.nix
        ./modules/poketwo/kubernetes.nix
        ./modules/poketwo/locale.nix
        ./modules/poketwo/network.nix
        ./modules/poketwo/shell.nix
        ./modules/poketwo/tailscale.nix
        ./profiles/base.nix
      ];

      # Put modules for specific hosts here.
      hosts = nixpkgs.lib.concatMapAttrs
        (filename: _: {
          ${nixpkgs.lib.nameFromURL filename "."} = [
            ./hosts/${filename}
          ];
        })
        (builtins.readDir ./hosts);

      # =====================
      # nixpkgs Configuration
      # =====================

      overlays = [
        agenix.overlays.default
      ];

      # =====================
      # Colmena Configuration
      # =====================

      pkgs-x86_64-linux = import nixpkgs {
        inherit overlays;
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

      devShellOutputs = flake-utils.lib.eachDefaultSystem (system:
        let pkgs = import nixpkgs { inherit system overlays; }; in {
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.colmena
              pkgs.agenix
            ];
          };
        }
      );
    in
    colmenaOutputs // devShellOutputs;
}
