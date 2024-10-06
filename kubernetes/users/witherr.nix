{ ... }:

let
  adminRoleBinding = {
    subjects = [{
      kind = "ServiceAccount";
      name = "witherr";
      namespace = "poketwo";
    }];
    roleRef = {
      kind = "ClusterRole";
      name = "admin";
      apiGroup = "rbac.authorization.k8s.io";
    };
  };
in
{
  namespaces.poketwo.resources = {
    v1.ServiceAccount.witherr = { };
    "rbac.authorization.k8s.io/v1".RoleBinding.witherr = adminRoleBinding;
    "rbac.authorization.k8s.io/v1".ClusterRoleBinding.witherr = adminRoleBinding;
  };

  namespaces.guiduck.resources."rbac.authorization.k8s.io/v1".RoleBinding.witherr = adminRoleBinding;
  namespaces.poketwo-staging.resources."rbac.authorization.k8s.io/v1".RoleBinding.witherr = adminRoleBinding;
  namespaces.poketwo-staging-private.resources."rbac.authorization.k8s.io/v1".RoleBinding.witherr = adminRoleBinding;
}
