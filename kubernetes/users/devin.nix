{ ... }:

let
  devinRoleAndBinding = {
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
          verbs = [ "get" "list" "watch" "delete" ];
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
  } // devinRoleAndBinding;

  namespaces.poketwo-staging.resources = devinRoleAndBinding;
  namespaces.poketwo-staging-private.resources = devinRoleAndBinding;
  namespaces.guiduck.resources = devinRoleAndBinding;
}
