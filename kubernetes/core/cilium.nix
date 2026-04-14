{ transpire, ... }:

{
  namespaces.cilium = {
    helmReleases.cilium = {
      chart = transpire.fetchFromHelm {
        repo = "https://helm.cilium.io/";
        name = "cilium";
        version = "1.19.2";
        sha256 = "dOd46T4+iKTIWAhr6f/yciIQM2jz/tvwP9AnA8uqX2Q=";
      };

      values = {
        extraArgs = [ "--devices=inet0" "--direct-routing-device=inet0" ];

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

        # Bypass socket LB in pod namespaces so Tailscale operator's
        # netfilter-based firewall rules work correctly.
        # https://tailscale.com/kb/1236/kubernetes-operator#cilium-in-kube-proxy-replacement-mode
        socketLB = {
          enabled = true;
          hostNamespaceOnly = true;
        };

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

        # Cilium L2 Announcements now supports IPv6/NDP (as of 1.19).
        # Consider using this instead of MetalLB.
        # https://docs.cilium.io/en/stable/network/l2-announcements/
        # l2announcements.enabled = true;

        # Cilium Kubernetes Ingress Controller
        # https://docs.cilium.io/en/stable/network/servicemesh/ingress/
        # Currently broken :(
        # ingressController = {
        #   enabled = true;
        #   default = true;
        # };

        # Override cni init container resource limits to use string values
        # (chart defaults cpu to integer 1, but Kubernetes API expects strings)
        cni.resources.limits.cpu = "1";

        # breaks for some reason
        envoy.enabled = false;
      };
    };

    resources."cilium.io/v2".CiliumClusterwideNetworkPolicy.deny-external.spec = {
      endpointSelector = { };
      ingress = [{ fromEntities = [ "cluster" ]; }];
      egress = [{ toEntities = [ "all" ]; }];
    };

    # Allow ingress from Tailscale IPs so traffic routed through the
    # tailnet can reach cluster services. The Connector forwards packets
    # without SNAT, so the source IP is the client's Tailscale address
    # (fd7a:115c:a1e0::/48), not the Connector pod's IP.
    resources."cilium.io/v2".CiliumClusterwideNetworkPolicy.allow-tailscale.spec = {
      endpointSelector = { };
      ingress = [{
        fromCIDRSet = [{
          cidr = "fd7a:115c:a1e0::/48";
        }];
      }];
    };
  };
}
