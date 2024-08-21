{ transpire, ... }:

{
  namespaces.cilium = {
    helmReleases.cilium = {
      chart = transpire.fetchFromHelm {
        repo = "https://helm.cilium.io/";
        name = "cilium";
        version = "1.16.1";
        sha256 = "+51oGLnIAzeJd+yPTXOOhvcR5UNMOPAxd4Hu6LpvhbU=";
      };

      values = {
        extraArgs = [ "--direct-routing-device=inet0" ];

        # We use Kubernetes IPAM, but KCM isn't configured to allocate addresses
        # since we need more control over the CIDRs (which are disjoint).
        # So, we apply the network.cilium.io/ipv6-pod-cidr annotation on Node
        ipam.mode = "kubernetes";
        annotateK8sNode = true;

        # Enable Cilium's kube-proxy replacement in Hybrid DSR/SNAT mode
        # https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/
        kubeProxyReplacement = true;
        k8sServiceHost = "ds.hfym.co";
        k8sServicePort = "443";
        loadBalancer.mode = "hybrid";
        endpointRoutes.enabled = true;

        # We use globally routable addresses for IPv6, so no NAT is needed.
        # We're running IPv6-only, but Discord still needs IPv4...
        # For now, that is accomplished with NAT64 on the host. :)
        ipv4.enabled = false;
        ipv6.enabled = true;
        routingMode = "native";
        enableIPv6Masquerade = false;

        # Observability things
        prometheus.enabled = true;
        dashboards.enabled = true;
        hubble = {
          tls.auto.method = "cronJob";
          relay.enabled = true;
          ui.enabled = true;
        };

        # Cilium L2 Announcements doesn't currently support IPv6/NDP.
        # When it does, we can consider using this instead of MetalLB.
        # https://docs.cilium.io/en/stable/network/l2-announcements/
        # l2announcements.enabled = true;

        # Cilium Kubernetes Ingress Controller
        # https://docs.cilium.io/en/stable/network/servicemesh/ingress/
        # Currently broken :(
        # ingressController = {
        #   enabled = true;
        #   default = true;
        # };

        # breaks for some reason
        envoy.enabled = false;
      };
    };

    resources."cilium.io/v2".CiliumClusterwideNetworkPolicy.deny-external.spec = {
      endpointSelector = { };
      ingress = [{ fromEntities = [ "cluster" ]; }];
      egress = [{ toEntities = [ "all" ]; }];
    };
  };
}
