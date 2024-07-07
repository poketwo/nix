{ transpire, ... }:

{
  namespaces.velero = {
    helmReleases.velero = {
      chart = transpire.fetchFromHelm {
        repo = "https://vmware-tanzu.github.io/helm-charts";
        name = "velero";
        version = "6.7.0";
        sha256 = "GPIh4HQHJRBS8BBJn+YmOjQebMwDzhVwThdrM9xMKUM=";
      };

      values = {
        initContainers = [
          {
            name = "velero-plugin-for-csi";
            image = "velero/velero-plugin-for-csi:v0.7.0";
            volumeMounts = [{ mountPath = "/target"; name = "plugins"; }];
          }
          {
            name = "velero-plugin-for-aws";
            image = "velero/velero-plugin-for-aws:v1.9.0";
            volumeMounts = [{ mountPath = "/target"; name = "plugins"; }];
          }
        ];

        deployNodeAgent = true;

        configuration = {
          features = "EnableCSI";

          backupStorageLocation = [{
            name = "default";
            provider = "velero.io/aws";
            bucket = "hfym-backups";
            credential = { name = "backblaze-b2-credentials"; key = "aws-config"; };
            config = {
              s3Url = "https://s3.us-west-000.backblazeb2.com";
              region = "us-west-000";
            };
          }];

          volumeSnapshotLocation = [{
            name = "default";
            provider = "csi";
          }];
        };

        schedules.daily = {
          schedule = "0 4 * * *";
          template = {
            ttl = "168h";
            snapshotMoveData = true;
            excludedNamespaces = [ "velero" ];
          };
        };

        nodeAgent.resources = {
          requests = { cpu = "500m"; memory = "64Mi"; };
          limits = { cpu = "2"; memory = "8Gi"; };
        };
      };

      includeCRDs = true;
    };

    resources.v1.Secret.backblaze-b2-credentials = {
      type = "Opaque";
      stringData.aws-config = "";
    };
  };
}
