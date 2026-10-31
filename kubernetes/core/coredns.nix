{ ... }:

# CoreDNS, taken over from the kubeadm addon (skipped via skipPhases in
# modules/poketwo/kubernetes.nix) so the Corefile edits are declarative.
let
  labels.k8s-app = "kube-dns";
in
{
  namespaces.kube-system = {
    resources = {
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
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "system:coredns";
        };
        subjects = [{
          kind = "ServiceAccount";
          name = "coredns";
          namespace = "kube-system";
        }];
      };

      "v1".ConfigMap.coredns.data.Corefile = ''
        .:53 {
            errors
            health {
               lameduck 5s
            }
            ready
            rewrite name regex (.+)\.(.+)\.svc\.ds\.hfym\.co {1}.{2}.svc.cluster.local answer auto
            kubernetes cluster.local in-addr.arpa ip6.arpa {
               pods insecure
               fallthrough in-addr.arpa ip6.arpa
               ttl 30
            }
            prometheus :9153
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

      "apps/v1".Deployment.coredns = {
        metadata.labels = labels;
        spec = {
          replicas = 2;
          selector.matchLabels = labels;
          strategy.rollingUpdate.maxUnavailable = 1;
          template = {
            metadata.labels = labels;
            spec = {
              priorityClassName = "system-cluster-critical";
              serviceAccountName = "coredns";
              dnsPolicy = "Default";
              nodeSelector."kubernetes.io/os" = "linux";
              tolerations = [
                { key = "CriticalAddonsOnly"; operator = "Exists"; }
                { key = "node-role.kubernetes.io/control-plane"; effect = "NoSchedule"; }
              ];
              affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution = [{
                weight = 100;
                podAffinityTerm = {
                  topologyKey = "kubernetes.io/hostname";
                  labelSelector.matchExpressions = [{ key = "k8s-app"; operator = "In"; values = [ "kube-dns" ]; }];
                };
              }];
              containers = [{
                name = "coredns";
                image = "registry.k8s.io/coredns/coredns:v1.11.3";
                args = [ "-conf" "/etc/coredns/Corefile" ];
                ports = [
                  { name = "dns"; containerPort = 53; protocol = "UDP"; }
                  { name = "dns-tcp"; containerPort = 53; protocol = "TCP"; }
                  { name = "metrics"; containerPort = 9153; protocol = "TCP"; }
                ];
                resources = {
                  requests = { cpu = "100m"; memory = "70Mi"; };
                  limits.memory = "170Mi";
                };
                livenessProbe = {
                  httpGet = { path = "/health"; port = 8080; };
                  initialDelaySeconds = 60;
                  timeoutSeconds = 5;
                  failureThreshold = 5;
                };
                readinessProbe.httpGet = { path = "/ready"; port = 8181; };
                securityContext = {
                  allowPrivilegeEscalation = false;
                  readOnlyRootFilesystem = true;
                  capabilities = { add = [ "NET_BIND_SERVICE" ]; drop = [ "ALL" ]; };
                };
                volumeMounts = [{ name = "config-volume"; mountPath = "/etc/coredns"; readOnly = true; }];
              }];
              volumes = [{
                name = "config-volume";
                configMap = {
                  name = "coredns";
                  items = [{ key = "Corefile"; path = "Corefile"; }];
                };
              }];
            };
          };
        };
      };

      "v1".Service.kube-dns = {
        metadata = {
          labels = labels // {
            "kubernetes.io/cluster-service" = "true";
            "kubernetes.io/name" = "CoreDNS";
          };
          annotations = {
            "prometheus.io/port" = "9153";
            "prometheus.io/scrape" = "true";
          };
        };
        spec = {
          clusterIP = "2606:c2c0:5:1:2::a";
          selector = labels;
          ports = [
            { name = "dns"; port = 53; protocol = "UDP"; }
            { name = "dns-tcp"; port = 53; protocol = "TCP"; }
            { name = "metrics"; port = 9153; protocol = "TCP"; }
          ];
        };
      };
    };
  };
}
