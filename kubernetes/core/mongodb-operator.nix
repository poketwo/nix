{ lib, config, transpire, ... }:

let
  # The operator is weird and requires that every namespace that wants to deploy
  # MongoDB resources have a service account. This is a bit of a pain, but we
  # can copy over the service account from the operator's namespace.

  # https://github.com/mongodb/mongodb-kubernetes-operator/issues/850

  # We do some Nix magic here. Essentially, we look for all namespaces that have
  # MongoDBCommunity resources and copy over the service account from the
  # operator's namespace. We can do this by defining a submodule that Nix will
  # merge with the existing `namespaces` submodule provided by transpire.

  operatorResources = config.namespaces.mongodb-operator.resources;

  resourcesToCopy = {
    v1.ServiceAccount.mongodb-database = null;
    "rbac.authorization.k8s.io/v1".Role.mongodb-database = null;
    "rbac.authorization.k8s.io/v1".RoleBinding.mongodb-database = null;
  };

  namespaceModule = { config, name, ... }:
    let
      hasMongos = config.resources."mongodbcommunity.mongodb.com/v1".MongoDBCommunity != { };
      overrideNs = obj: lib.mkMerge [ obj { metadata.namespace = lib.mkForce name; } ];
      copiedResources = lib.mapAttrsRecursive
        (path: _: overrideNs (lib.getAttrFromPath path operatorResources))
        resourcesToCopy;
    in
    {
      resources = lib.mkIf (name != "mongodb-operator" && hasMongos) copiedResources;
    };
in
{
  options = {
    namespaces = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule namespaceModule);
    };
  };

  config = {
    namespaces.mongodb-operator = {
      helmReleases.mongodb-operator = {
        chart = transpire.fetchFromHelm {
          repo = "https://mongodb.github.io/helm-charts";
          name = "community-operator";
          version = "0.9.0";
          sha256 = "OvHPiqHinxSD7vYtYKlfuvgNjG6+6jLZwIlpvFvMOZ8=";
        };

        values = {
          operator.watchNamespace = "*";
        };
      };
    };
  };
}
