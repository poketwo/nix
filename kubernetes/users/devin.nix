{ ... }:

let
  devinRoleAndBinding = ns: {
    "rbac.authorization.k8s.io/v1".Role.devin = {
      rules = [
        {
          apiGroups = [ "apps" ];
          resources = [ "statefulsets" "deployments" ];
          verbs = [ "get" "list" "patch" ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "pods" ];
          verbs = [ "get" "list" "delete" ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "pods/log" ];
          verbs = [ "get" ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "services" "configmaps" "events" ];
          verbs = [ "get" "list" ];
        }
      ];
    };

    "rbac.authorization.k8s.io/v1".RoleBinding.devin = {
      subjects = [{
        kind = "ServiceAccount";
        name = "devin";
        namespace = "poketwo";
      }];
      roleRef = {
        kind = "Role";
        name = "devin";
        apiGroup = "rbac.authorization.k8s.io";
      };
    };
  };
in
{
  namespaces.poketwo.resources = {
    v1.ServiceAccount.devin = { };
  } // devinRoleAndBinding "poketwo";

  namespaces.poketwo-staging.resources = devinRoleAndBinding "poketwo-staging";
  namespaces.poketwo-staging-private.resources = devinRoleAndBinding "poketwo-staging-private";
  namespaces.guiduck.resources = devinRoleAndBinding "guiduck";
}
