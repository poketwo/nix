{ lib, transpire, ... }:

let
  # All three nodes happen to have drives in the same place. (right now)
  commonDevices = [
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1"; }
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1"; }
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:05:00.0-nvme-1-part3"; }
  ];

  defaultPool = {
    failureDomain = "host";
    replicated.size = 3;
    deviceClass = "nvme";
  };

  commonStorageClassOptions = {
    parameters = {
      clusterID = "rook-ceph";
      "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
      "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
      "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
    };
    allowVolumeExpansion = true;
    reclaimPolicy = "Delete";
  };

  withCommonStorageClassOptions = attrs: lib.mkMerge [ commonStorageClassOptions attrs ];
in
{
  namespaces.rook-ceph = {
    helmReleases.rook-ceph = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.rook.io/release";
        name = "rook-ceph";
        version = "1.14.4";
        sha256 = "vlWXg2Huq/bk0xCVwxJOGe7fzKphK4jlqDn9NvtO3QI=";
      };

      values = {
        monitoring.enabled = true;

        # Specify NixOS kernel modules path
        # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/#cephfs
        # https://github.com/rook/rook/blob/v1.14.4/deploy/charts/rook-ceph/values.yaml#L189-L217
        csi = {
          csiRBDPluginVolume = [
            { name = "lib-modules"; hostPath = { path = "/run/booted-system/kernel-modules/lib/modules/"; }; }
            { name = "host-nix"; hostPath = { path = "/nix"; }; }
          ];
          csiRBDPluginVolumeMount = [
            { name = "host-nix"; mountPath = "/nix"; readOnly = true; }
          ];
          csiCephFSPluginVolume = [
            { name = "lib-modules"; hostPath = { path = "/run/booted-system/kernel-modules/lib/modules/"; }; }
            { name = "host-nix"; hostPath = { path = "/nix"; }; }
          ];
          csiCephFSPluginVolumeMount = [
            { name = "host-nix"; mountPath = "/nix"; readOnly = true; }
          ];
        };
      };
    };

    # ==========================
    # Ceph Cluster Configuration
    # ==========================

    resources."ceph.rook.io/v1".CephCluster.rook-ceph.spec = {
      cephVersion.image = "quay.io/ceph/ceph:v18.2.2";
      dataDirHostPath = "/var/lib/rook";
      mon = { count = 3; allowMultiplePerNode = false; };
      mgr = {
        count = 2;
        allowMultiplePerNode = false;
        modules = [{ name = "rook"; enabled = true; }];
      };
      dashboard = { enabled = true; ssl = true; };
      storage = {
        useAllNodes = false;
        useAllDevices = false;
        nodes = [
          { name = "vaporeon"; devices = commonDevices; }
          { name = "jolteon"; devices = commonDevices; }
          { name = "flareon"; devices = commonDevices; }
        ];
      };
    };

    # Block Storage
    resources."ceph.rook.io/v1".CephBlockPool.rbd-nvme.spec = defaultPool;

    # CephFS
    resources."ceph.rook.io/v1".CephFilesystem.cephfs-nvme.spec = {
      metadataPool = defaultPool;
      dataPools = [ (defaultPool // { name = "nvme"; }) ];
      preserveFilesystemOnDelete = true;
      metadataServer = { activeCount = 1; activeStandby = true; };
    };

    # Object Storage
    resources."ceph.rook.io/v1".CephObjectStore.rgw-nvme.spec = {
      metadataPool = defaultPool;
      dataPool = defaultPool;
      gateway = { port = 80; securePort = 443; instances = 1; };
    };

    # ==========================
    # StorageClass Configuration
    # ==========================

    resources."storage.k8s.io/v1".StorageClass = {
      rbd-nvme = withCommonStorageClassOptions {
        metadata.annotations."storageclass.kubernetes.io/is-default-class" = "true";
        provisioner = "rook-ceph.rbd.csi.ceph.com";
        parameters = {
          pool = "rbd-nvme";
          imageFormat = "2";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-rbd-node";
          "csi.storage.k8s.io/fstype" = "ext4";
          # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/#rbd
          imageFeatures = "layering,fast-diff,object-map,deep-flatten,exclusive-lock";
        };
      };

      cephfs-nvme = withCommonStorageClassOptions {
        provisioner = "rook-ceph.cephfs.csi.ceph.com";
        parameters = {
          fsName = "cephfs-nvme";
          pool = "cephfs-nvme";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-cephfs-node";
        };
      };

      rgw-nvme = {
        provisioner = "rook-ceph.ceph.rook.io/bucket";
        reclaimPolicy = "Delete";
        parameters = { objectStoreName = "rgw-nvme"; objectStoreNamespace = "rook-ceph"; };
      };
    };
  };
}
