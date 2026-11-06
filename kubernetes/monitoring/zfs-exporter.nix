{ ... }:

{
  # ZFS pool/dataset free space. Snapshots count against it, unlike the xfs
  # inside the mongo zvol.
  namespaces.prometheus.resources."apps/v1".DaemonSet.zfs-exporter.spec = {
    selector.matchLabels.app = "zfs-exporter";

    template = {
      metadata.labels.app = "zfs-exporter";

      spec = {
        containers.zfs-exporter = {
          image = "ghcr.io/pdf/zfs_exporter:v2.5.1";
          ports = [{ name = "metrics"; containerPort = 9134; }];

          # Per-snapshot used/referenced/written, so snapshot space shows up in
          # Grafana without SSHing to vaporeon/jolteon.
          args = [ "--collector.dataset-snapshot" ];

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
