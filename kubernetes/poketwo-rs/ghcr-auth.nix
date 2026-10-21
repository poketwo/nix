{ ... }:

{
  namespaces.poketwo-rs.resources = {
    v1.Secret.ghcr-auth = {
      type = "kubernetes.io/dockerconfigjson";
      stringData.".dockerconfigjson" = "";
    };
  };
}
