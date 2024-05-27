{
  description = "NixOS configuration for Pokétwo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    agenix.url = "github:ryantm/agenix";
    transpire.url = "github:oliver-ni/transpire";

    agenix.inputs.nixpkgs.follows = "nixpkgs";
    transpire.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, systems, agenix, transpire }:
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
      hosts = nixpkgs.lib.mapAttrs'
        (filename: _: {
          name = nixpkgs.lib.nameFromURL filename ".";
          value = [ ./hosts/${filename} ];
        })
        (builtins.readDir ./hosts);

      # =====================
      # nixpkgs Configuration
      # =====================

      overlays = [
        agenix.overlays.default
      ];

      pkgsFor = system: import nixpkgs {
        inherit overlays system;
        config = { allowUnfree = true; };
      };

      # =====================
      # Colmena Configuration
      # =====================

      colmenaHosts = builtins.mapAttrs
        (host: modules: {
          imports = commonModules ++ modules;
          deployment.buildOnTarget = true;
          deployment.targetUser = "oliver";
          deployment.allowLocalDeployment = true;
        })
        hosts;

      forAllSystems = fn: nixpkgs.lib.genAttrs
        (import systems)
        (system: fn system (pkgsFor system));
    in
    {
      colmena = colmenaHosts // {
        meta = { nixpkgs = pkgsFor "x86_64-linux"; };
      };

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.colmena pkgs.agenix ];
        };
      });

      packages = forAllSystems (system: pkgs: {
        kubernetes = transpire.lib.${system}.build.cluster {
          modules = pkgs.lib.mapAttrsToList
            (filename: _: ./kubernetes/${filename})
            (builtins.readDir ./kubernetes);
        };
      });
    };
}
