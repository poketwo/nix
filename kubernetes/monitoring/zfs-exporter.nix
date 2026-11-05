{ ... }:

{
  # ZFS pool/dataset free space on the mongo hosts. Snapshots count against
  # it, unlike the xfs inside the mongo zvol.
  namespaces.prometheus.resources."apps/v1".DaemonSet.zfs-exporter.spec = {
    selector.matchLabels.app = "zfs-exporter";

    template = {
      metadata.labels.app = "zfs-exporter";

      spec = {
        affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [{
          matchExpressions = [{
            key = "kubernetes.io/hostname";
            operator = "In";
            values = [ "vaporeon" "jolteon" ];
          }];
        }];

        containers.zfs-exporter = {
          image = "ghcr.io/pdf/zfs_exporter:v2.5.1";
          ports = [{ name = "metrics"; containerPort = 9134; }];

          # Runs the host's zfs/zpool chrooted into /host; needs /dev/zfs.
          securityContext.privileged = true;

          volumeMounts = [{
            name = "host-root";
            mountPath = "/host";
            readOnly = true;
            mountPropagation = "HostToContainer";
          }];
        };

        volumes = [{
          name = "host-root";
          hostPath.path = "/";
        }];
      };
    };
  };
}
