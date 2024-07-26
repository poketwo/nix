{ ... }:

{
  namespaces.poketwo.resources = {
    v1.ServiceAccount.witherr = { };

    "rbac.authorization.k8s.io/v1".RoleBinding.witherr = {
      subjects = [{
        kind = "ServiceAccount";
        name = "witherr";
      }];
      roleRef = {
        kind = "ClusterRole";
        name = "admin";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };

    "rbac.authorization.k8s.io/v1".ClusterRoleBinding.witherr = {
      subjects = [{
        kind = "ServiceAccount";
        name = "witherr";
        namespace = "poketwo";
      }];
      roleRef = {
        kind = "ClusterRole";
        name = "view";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };
  };
}
