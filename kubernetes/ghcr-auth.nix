{ lib, ... }:

{
  # Pull secret for private ghcr.io/poketwo images
  namespaces = lib.genAttrs [ "poketwo" "poketwo-staging" "poketwo-staging-private" "guiduck" ] (_: {
    resources.v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };
  });
}
