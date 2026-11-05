{ ... }:

{
  # ZFS pool/dataset free space on the mongo hosts. Snapshots count against
  # it, unlike the xfs inside the mongo zvol. Scraped by Alloy via `metrics`.
  namespaces.prometheus.resources."apps/v1".DaemonSet.zfs-exporter.spec = {
    selector.matchLabels."app.kubernetes.io/name" = "zfs-exporter";
    template = {
      metadata.labels."app.kubernetes.io/name" = "zfs-exporter";
      spec = {
        affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [{
          matchExpressions = [{ key = "kubernetes.io/hostname"; operator = "In"; values = [ "vaporeon" "jolteon" ]; }];
        }];
        automountServiceAccountToken = false;
        containers.zfs-exporter = {
          image = "ghcr.io/pdf/zfs_exporter:v2.5.1";
          args = [ "--web.listen-address=[::]:9134" ];
          ports = [{ name = "metrics"; containerPort = 9134; }];
          # Runs the host's zfs/zpool chrooted into /host; needs /dev/zfs.
          securityContext = { privileged = true; readOnlyRootFilesystem = true; };
          resources = {
            limits.memory = "64Mi";
            requests = { memory = "16Mi"; cpu = "10m"; };
          };
          volumeMounts = [{ name = "host-root"; mountPath = "/host"; readOnly = true; mountPropagation = "HostToContainer"; }];
        };
        volumes = [{ name = "host-root"; hostPath.path = "/"; }];
      };
    };
  };
}
