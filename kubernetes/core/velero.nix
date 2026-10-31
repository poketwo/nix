{ transpire, ... }:

{
  namespaces.velero = {
    helmReleases.velero = {
      chart = transpire.fetchFromHelm {
        repo = "https://vmware-tanzu.github.io/helm-charts";
        name = "velero";
        version = "11.4.0";
        sha256 = "8PrcU3pX02Q/z6UeffM1sJckSSC13TBIE8gwvAs94Ss=";
      };

      values = {
        kubectl.image.repository = "docker.io/bitnamilegacy/kubectl";
        kubectl.image.tag = "1.33.4";

        initContainers = [
          {
            name = "velero-plugin-for-aws";
            image = "velero/velero-plugin-for-aws:v1.13.2";
            volumeMounts = [{ mountPath = "/target"; name = "plugins"; }];
          }
        ];

        deployNodeAgent = true;

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

          volumeSnapshotLocation = [{
            name = "default";
            provider = "csi";
          }];
        };

        schedules = {
          daily = {
            schedule = "30 4 * * *";
            template = {
              ttl = "168h";
              snapshotMoveData = true;
              excludedNamespaces = [ "velero" ];
            };
          };
          hourly = {
            schedule = "0 * * * *";
            template = {
              ttl = "24h";
              snapshotMoveData = true;
              excludedNamespaces = [ "velero" ];
            };
          };
        };

        nodeAgent.resources = {
          requests = { cpu = "500m"; memory = "64Mi"; };
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
