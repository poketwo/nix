{ ... }:

{
  namespaces.poketwo.resources = {
    v1.ServiceAccount.devin = { };

    "rbac.authorization.k8s.io/v1".Role.devin-restart = {
      rules = [{
        apiGroups = [ "apps" ];
        resources = [ "statefulsets" ];
        verbs = [ "get" "patch" ];
      }];
    };

    "rbac.authorization.k8s.io/v1".RoleBinding.devin-restart = {
      subjects = [{
        kind = "ServiceAccount";
        name = "devin";
        namespace = "poketwo";
      }];
      roleRef = {
        kind = "Role";
        name = "devin-restart";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };
  };
}
