{ lib, config, ... }:

let
  useVaultSecrets = { apiVersion, kind, metadata, ... }@obj:
    if apiVersion == "v1" && kind == "Secret"
      && !(builtins.elem "${metadata.namespace}/${metadata.name}" config.vaultSecrets.exclude) then
      {
        inherit metadata;
        apiVersion = "secrets.hashicorp.com/v1beta1";
        kind = "VaultStaticSecret";
        spec = {
          type = "kv-v2";
          mount = "hfym-ds";
          path = "${metadata.namespace}/${metadata.name}";
          destination = {
            inherit (metadata) name;
            create = true;
            type = obj.type or "Opaque";
          };
        };
      }
    else obj;
in
{
  options.vaultSecrets.exclude = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "Secrets (as `namespace/name`) to render as-is instead of syncing from Vault.";
    default = [ ];
  };

  config.transforms = [ useVaultSecrets ];
}
