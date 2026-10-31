{ transpire, ... }:

{
  namespaces.velero = {
    helmReleases.velero = {
      chart = transpire.fetchFromHelm {
        repo = "https://vmware-tanzu.github.io/helm-charts";
        name = "velero";
        version = "12.2.2";
        sha256 = "ACcKsEe2foDG7gakvtvgYcZiYhzptJufMgIKIii2jiQ=";
      };

      values = {
        image.tag = "v1.18.4";

        initContainers = [
          {
            name = "velero-plugin-for-aws";
            image = "velero/velero-plugin-for-aws:v1.14.4";
            volumeMounts = [{ mountPath = "/target"; name = "plugins"; }];
          }
        ];

        deployNodeAgent = true;
        credentials.useSecret = false;

        configuration = {
          features = "EnableCSI";

          backupStorageLocation = [{
            name = "default";
            provider = "velero.io/aws";
            bucket = "hfym-ds-backups";
            credential = { name = "r2-credentials"; key = "aws-config"; };
            config = {
              s3Url = "https://ccff77448651723b79f4612a5200cbb8.r2.cloudflarestorage.com";
              region = "auto";
              checksumAlgorithm = "";
            };
          }];

          volumeSnapshotLocation = [ ];
          # CephFS clones copy the whole volume; a 64 GiB one exceeded the 30m default
          dataMoverPrepareTimeout = "2h";
        };

        schedules = {
          daily = {
            schedule = "30 4 * * *";
            template = {
              ttl = "168h";
              snapshotMoveData = true;
              excludedNamespaces = [ "velero" "kube-system" "cilium" "rook-ceph" "argocd" "cert-manager" ];
            };
          };
        };

        nodeAgent.resources = {
          requests = { cpu = "500m"; memory = "1Gi"; };
          limits = { cpu = "2"; memory = "8Gi"; };
        };
      };

      includeCRDs = true;
    };

    resources.v1.Secret.r2-credentials = {
      type = "Opaque";
      stringData.aws-config = "";
    };
  };
}
