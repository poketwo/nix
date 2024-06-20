{ pkgs, ... }:

let
  external-snapshotter = pkgs.fetchFromGitHub {
    owner = "kubernetes-csi";
    repo = "external-snapshotter";
    rev = "v8.0.1";
    sha256 = "pWSLjZNLpFMVpTVr3PJ4C6tk+W0TiPeiZfhxqcNi8aE=";
  };
in
{
  namespaces.snapshot-controller = {
    # Note: These things actually end up in kube-system. We can't just override
    # the namespace because the ClusterRoleBinding is hardcoded as kube-system.
    overrideNamespace = false;

    kustomizations = {
      snapshot-crds = "${external-snapshotter}/client/config/crd";
      snapshot-controller = "${external-snapshotter}/deploy/kubernetes/snapshot-controller";
    };
  };
}
