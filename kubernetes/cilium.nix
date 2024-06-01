{ transpire, ... }:

{
  namespaces.cilium = {
    helmReleases.cilium = {
      chart = transpire.fetchFromHelm {
        repo = "https://helm.cilium.io/";
        name = "cilium";
        version = "1.15.5";
        sha256 = "33J0dGfxtw5qfMBZGl6C2xyt5xE2AT+fGLJNrNKwM6g=";
      };

      values = {
        # We use Kubernetes IPAM, but KCM isn't configured to allocate addresses
        # since we need more control over the CIDRs (disjoint).
        # So, we apply the network.cilium.io/ipv6-pod-cidr annotation on Node
        ipam.mode = "kubernetes";
        annotateK8sNode = true;

        # Enable Cilium's kube-proxy replacement.
        # https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/
        kubeProxyReplacement = true;
        k8sServiceHost = "ds.hfym.co";
        k8sServicePort = "443";

        # TODO: Look into this
        # nat46x64Gateway.enabled = true;

        # Cilium L2 Announcements doesn't currently support IPv6/NDP.
        # When it does, we can consider using this instead of MetalLB.
        # https://docs.cilium.io/en/stable/network/l2-announcements/
        # l2announcements.enabled = true;

        # Cilium Kubernetes Ingress Controller
        # https://docs.cilium.io/en/stable/network/servicemesh/ingress/
        ingressController = {
          enable = true;
          default = true;
          loadbalancerMode = "shared";
        };

        # Apparently this is good so I'm turning it on
        endpointRoutes.enabled = true;

        # Maybe look into Gateway API (Ingress successor) in the future
        # https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/
        # gatewayAPI.enabled = true;

        # This cluter is IPv6-only.
        ipv4.enabled = false;
        ipv6.enabled = true;
        enableIPv6Masquerade = false;

        # Metrics
        prometheus.enabled = true;
        dashboards.enabled = true;

        # Native mode delegates routing to node's networking stack
        # We can do this because IPV6, hopefully
        routingMode = "native";

        hubble = {
          tls.auto.method = "cronJob";
          relay.enabled = true;
          ui.enabled = true;
        };
      };
    };

    resources."cilium.io/v2".CiliumClusterwideNetworkPolicy.deny-external.spec = {
      endpointSelector = { };
      ingress = [{ fromEntities = [ "cluster" ]; }];
    };

    resources.v1.Service.hedgedoc.spec = {
      ports = [{ port = 80; targetPort = 3000; }];
      selector.app = "hedgedoc";
    };
  };
}
