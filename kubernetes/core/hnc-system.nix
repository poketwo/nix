{ pkgs, ... }:

let
  hncVersion = "v1.1.0";
  hncVariant = "default-cm";

  hnc = pkgs.fetchurl {
    url = "https://github.com/kubernetes-sigs/hierarchical-namespaces/releases/download/${hncVersion}/${hncVariant}.yaml";
    sha256 = "5GKuIBmtomWWsT0zBEkNlmzD6Eip0v+bb1iWns/66Os=";
  };
in
{
  namespaces.hnc-system = {
    manifests = [ hnc ];
  };
}
