{ transpire, ... }:

let
  # All three nodes happen to have drives in the same place. (right now)
  commonDevices = [
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1"; }
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1"; }
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:05:00.0-nvme-1-part3"; }
  ];

  commonDevicesWithoutBootDrive = [
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:03:00.0-nvme-1"; }
    { config.deviceClass = "nvme"; name = "/dev/disk/by-path/pci-0000:04:00.0-nvme-1"; }
  ];

  defaultPool = {
    failureDomain = "host";
    replicated.size = 2;
    deviceClass = "nvme";
  };

  commonStorageClassParamters = {
    clusterID = "rook-ceph";
    "csi.storage.k8s.io/provisioner-secret-namespace" = "rook-ceph";
    "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph";
    "csi.storage.k8s.io/node-stage-secret-namespace" = "rook-ceph";
  };
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
      cephVersion.image = "quay.io/ceph/ceph:v18.2.2-20240521";
      dataDirHostPath = "/var/lib/rook";
      mon = { count = 3; allowMultiplePerNode = false; };
      mgr = { count = 2; allowMultiplePerNode = false; };
      mgr.modules = [{ name = "rook"; enabled = true; }];
      dashboard.enabled = true;
      network.ipFamily = "IPv6";
      storage = {
        useAllNodes = false;
        useAllDevices = false;
        nodes = [
          { name = "vaporeon"; devices = commonDevices; }
          { name = "jolteon"; devices = commonDevices; }
          { name = "flareon"; devices = commonDevicesWithoutBootDrive; }
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
      gateway = {
        port = 80;
        instances = 1;
      };
    };

    # Ingress for Object Storage
    resources."networking.k8s.io/v1".Ingress.rgw-nvme-ingress = {
      metadata.annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
      spec = {
        rules = [{
          host = "rgw.hfym.co";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "rook-ceph-rgw-rgw-nvme";
              port.number = 80;
            };
          }];
        }];
        tls = [{
          hosts = [ "rgw.hfym.co" ];
          secretName = "rgw-nvme-ingress-tls";
        }];
      };
    };

    # ==========================
    # StorageClass Configuration
    # ==========================

    resources."storage.k8s.io/v1".StorageClass = rec {
      rbd-nvme = {
        provisioner = "rook-ceph.rbd.csi.ceph.com";
        parameters = commonStorageClassParamters // {
          pool = "rbd-nvme";
          imageFormat = "2";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-rbd-node";
          "csi.storage.k8s.io/fstype" = "ext4";
          # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/#rbd
          imageFeatures = "layering,fast-diff,object-map,deep-flatten,exclusive-lock";
        };
        allowVolumeExpansion = true;
        reclaimPolicy = "Delete";
      };

      rbd-nvme-retain = rbd-nvme // {
        metadata.annotations."storageclass.kubernetes.io/is-default-class" = "true";
        allowVolumeExpansion = true;
        reclaimPolicy = "Retain";
      };

      cephfs-nvme = {
        provisioner = "rook-ceph.cephfs.csi.ceph.com";
        parameters = commonStorageClassParamters // {
          fsName = "cephfs-nvme";
          pool = "cephfs-nvme-nvme";
          "csi.storage.k8s.io/provisioner-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/controller-expand-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/node-stage-secret-name" = "rook-csi-cephfs-node";
        };
        allowVolumeExpansion = true;
        reclaimPolicy = "Delete";
      };

      cephfs-nvme-retain = cephfs-nvme // {
        allowVolumeExpansion = true;
        reclaimPolicy = "Retain";
      };

      rgw-nvme = {
        provisioner = "rook-ceph.ceph.rook.io/bucket";
        reclaimPolicy = "Delete";
        parameters = { objectStoreName = "rgw-nvme"; objectStoreNamespace = "rook-ceph"; };
      };
    };

    # =================================
    # VolumeSnapshotClass Configuration
    # =================================

    resources."snapshot.storage.k8s.io/v1".VolumeSnapshotClass = {
      csi-rbdplugin-snapclass = {
        driver = "rook-ceph.rbd.csi.ceph.com";
        parameters = {
          clusterID = "rook-ceph";
          "csi.storage.k8s.io/snapshotter-secret-name" = "rook-csi-rbd-provisioner";
          "csi.storage.k8s.io/snapshotter-secret-namespace" = "rook-ceph";
        };
        deletionPolicy = "Delete";
      };

      csi-cephfsplugin-snapclass = {
        driver = "rook-ceph.cephfs.csi.ceph.com";
        parameters = {
          clusterID = "rook-ceph";
          "csi.storage.k8s.io/snapshotter-secret-name" = "rook-csi-cephfs-provisioner";
          "csi.storage.k8s.io/snapshotter-secret-namespace" = "rook-ceph";
        };
        deletionPolicy = "Delete";
      };
    };
  };
}
