{ ... }:

let
  # Hosts with ZFS pools: the mongo zvols, whose snapshots eat pool space
  # that xfs inside the zvol can't see.
  zfsNodes = [ "vaporeon" "jolteon" ];
in

{
  # Pool/dataset free space (snapshots included). Runs the host's own zfs and
  # zpool chrooted into /host, so it always matches the kernel module. The
  # `metrics` port is picked up by the cluster Alloy's pod scrape.
  namespaces.prometheus.resources."apps/v1".DaemonSet.zfs-exporter.spec = {
    selector.matchLabels."app.kubernetes.io/name" = "zfs-exporter";
    template = {
      metadata.labels."app.kubernetes.io/name" = "zfs-exporter";
      spec = {
        affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms = [{
          matchExpressions = [{ key = "kubernetes.io/hostname"; operator = "In"; values = zfsNodes; }];
        }];
        automountServiceAccountToken = false;
        containers.zfs-exporter = {
          image = "ghcr.io/pdf/zfs_exporter:v2.5.1";
          args = [ "--web.listen-address=[::]:9134" ];
          ports = [{ name = "metrics"; containerPort = 9134; }];
          # Privileged is the only way to reach /dev/zfs without a device
          # plugin; zfs and zpool still run as nobody inside the chroot.
          securityContext = { privileged = true; readOnlyRootFilesystem = true; };
          resources = {
            limits.memory = "64Mi";
            requests = { memory = "16Mi"; cpu = "10m"; };
          };
          readinessProbe.httpGet = { path = "/"; port = "metrics"; };
          volumeMounts = [{
            name = "host-root";
            mountPath = "/host";
            readOnly = true;
            # Lets datasets the host unmounts leave the container too, so
            # they don't stay busy and block `zfs destroy`.
            mountPropagation = "HostToContainer";
          }];
        };
        volumes = [{ name = "host-root"; hostPath = { path = "/"; type = "Directory"; }; }];
      };
    };
  };
}
