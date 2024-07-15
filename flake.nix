{
  description = "NixOS configuration for Pokétwo";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    agenix.url = "github:ryantm/agenix";
    transpire.url = "github:oliver-ni/transpire";
    # transpire.url = "path:/Users/oliver/Development/github.com/oliver-ni/transpire-nix";

    agenix.inputs.nixpkgs.follows = "nixpkgs";
    transpire.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, systems, agenix, transpire, ... }:
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
        ./modules/poketwo/nat64.nix
        ./modules/poketwo/network.nix
        ./modules/poketwo/shell.nix
        ./modules/poketwo/tailscale.nix
        ./profiles/base.nix
      ];

      hosts = nixpkgs.lib.mapAttrs'
        (filename: _: {
          name = nixpkgs.lib.nameFromURL filename ".";
          value = [ ./hosts/${filename} ];
        })
        (builtins.readDir ./hosts);

      # =======================
      # Transpire Configuration
      # =======================

      fs = nixpkgs.lib.fileset;
      allNixFiles = fs.fileFilter (file: file.hasExt "nix") ./.;

      kubernetesExtraModules = fs.toList
        (fs.intersection allNixFiles ./kubernetes/extras);

      kubernetesModules = fs.toList
        (fs.intersection
          (fs.fileFilter (file: file.hasExt "nix") ./.)
          (fs.difference ./kubernetes ./kubernetes/extras));

      openApiSpec = ./kube-openapi.json;

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
          inherit openApiSpec;
          modules = kubernetesModules ++ kubernetesExtraModules;
        };

        docs = transpire.lib.${system}.buildDocs {
          inherit openApiSpec;
        };

        # This is used for the `push-vault-secrets` app
        # It's a bit of a hack, but it works for now :)
        __raw-secrets-to-push = builtins.groupBy
          (obj: obj.metadata.namespace)
          (builtins.filter
            (obj: obj.apiVersion == "v1" && obj.kind == "Secret")
            (transpire.lib.${system}.evalModules {
              inherit openApiSpec;
              modules = kubernetesModules;
            }).config.build.objects);
      });

      apps = forAllSystems (system: pkgs: {
        update-kube-openapi = {
          type = "app";
          program = toString (pkgs.writers.writeBash "update-kube-openapi" ''
            ${pkgs.kubectl}/bin/kubectl get --raw /openapi/v2 > kube-openapi.json
          '');
        };

        push-vault-secrets = {
          type = "app";
          program = toString (pkgs.writers.writeBash "push-vault-secrets" ''
            set -e
            if [[ $# -eq 0 ]] ; then
              echo 'Usage: push-vault-secrets <namespace>'
              exit 1
            fi
            nix eval --json --impure ".#__raw-secrets-to-push.$1" \
            | ${pkgs.jq}/bin/jq -r -c '.[] |
                .metadata.namespace + "/" + .metadata.name,
                (.data // {} | .[] |= @base64d) + (.stringData // {})
              ' \
            | while read -r path; read -r data; do
              read -r -p "Push $path? [y/N] " choice <&2
              if [[ $choice =~ ^[Yy] ]] ; then
                ${pkgs.vault-bin}/bin/vault kv put -mount=hfym-ds "$path" - <<< "$data" > /dev/null
              fi
            done
          '');
        };
      });
    };
}
