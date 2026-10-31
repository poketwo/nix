{ ... }:

# Cluster DNS. kubeadm's CoreDNS addon is skipped in modules/poketwo/kubernetes.nix,
# so the Corefile lives here instead of in a hand-edited ConfigMap.
let
  labels.k8s-app = "kube-dns";

  corefile = ''
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        prometheus :9153

        # <svc>.<ns>.svc.ds.hfym.co is an alias for <svc>.<ns>.svc.cluster.local
        rewrite name regex (.+)\.(.+)\.svc\.ds\.hfym\.co {1}.{2}.svc.cluster.local answer auto

        kubernetes cluster.local ip6.arpa {
            fallthrough ip6.arpa
            ttl 30
        }

        # IPv6-only cluster: hide A records so clients use the dns64 AAAA.
        acl {
            filter type A
        }
        dns64
        forward . /etc/resolv.conf

        cache 30
        loop
        reload
        loadbalance
    }
  '';

  container = {
    name = "coredns";
    image = "registry.k8s.io/coredns/coredns:v1.11.3";
    args = [ "-conf" "/etc/coredns/Corefile" ];
    ports = [
      { name = "dns"; containerPort = 53; protocol = "UDP"; }
      { name = "dns-tcp"; containerPort = 53; protocol = "TCP"; }
      { name = "metrics"; containerPort = 9153; }
    ];
    resources.requests = { cpu = "100m"; memory = "70Mi"; };
    livenessProbe.httpGet = { path = "/health"; port = 8080; };
    readinessProbe.httpGet = { path = "/ready"; port = 8181; };
    securityContext = {
      allowPrivilegeEscalation = false;
      readOnlyRootFilesystem = true;
      capabilities = { drop = [ "ALL" ]; add = [ "NET_BIND_SERVICE" ]; };
    };
    volumeMounts = [{ name = "config"; mountPath = "/etc/coredns"; readOnly = true; }];
  };

  pod = {
    priorityClassName = "system-cluster-critical";
    serviceAccountName = "coredns";
    # Use the node's resolver for `forward`, not ourselves.
    dnsPolicy = "Default";
    tolerations = [{ key = "node-role.kubernetes.io/control-plane"; effect = "NoSchedule"; }];
    # Never both replicas on one node, so a drain keeps DNS up.
    topologySpreadConstraints = [{
      maxSkew = 1;
      topologyKey = "kubernetes.io/hostname";
      whenUnsatisfiable = "DoNotSchedule";
      labelSelector.matchLabels = labels;
    }];
    containers = [ container ];
    volumes = [{ name = "config"; configMap.name = "coredns"; }];
  };
in
{
  namespaces.kube-system.resources = {
    "v1".ServiceAccount.coredns = { };

    "rbac.authorization.k8s.io/v1".ClusterRole."system:coredns".rules = [
      {
        apiGroups = [ "" ];
        resources = [ "endpoints" "services" "pods" "namespaces" ];
        verbs = [ "list" "watch" ];
      }
      {
        apiGroups = [ "discovery.k8s.io" ];
        resources = [ "endpointslices" ];
        verbs = [ "list" "watch" ];
      }
    ];

    "rbac.authorization.k8s.io/v1".ClusterRoleBinding."system:coredns" = {
      roleRef = { apiGroup = "rbac.authorization.k8s.io"; kind = "ClusterRole"; name = "system:coredns"; };
      subjects = [{ kind = "ServiceAccount"; name = "coredns"; namespace = "kube-system"; }];
    };

    "v1".ConfigMap.coredns.data.Corefile = corefile;

    "apps/v1".Deployment.coredns = {
      metadata.labels = labels;
      spec = {
        replicas = 2;
        selector.matchLabels = labels;
        template = { metadata.labels = labels; spec = pod; };
      };
    };

    "v1".Service.kube-dns = {
      metadata.labels = labels;
      spec = {
        clusterIP = "2606:c2c0:5:1:2::a";
        selector = labels;
        ports = [
          { name = "dns"; port = 53; protocol = "UDP"; }
          { name = "dns-tcp"; port = 53; protocol = "TCP"; }
        ];
      };
    };
  };
}
