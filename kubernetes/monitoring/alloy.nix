{ transpire, ... }:

{
  namespaces.alloy = {
    helmReleases.alloy = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "alloy";
        version = "1.15.0";
        sha256 = "efDrZJdDGVGHGkuC5KOE74IHz+/GrUJJU8RZwpY8lgE=";
      };

      values = {
        controller = {
          type = "statefulset";
          replicas = 3;
          # Keeps loki.source.kubernetes positions across restarts; without them
          # every tailer re-reads its container's whole log from the start.
          volumeClaimTemplates = [{
            metadata.name = "storage";
            spec = {
              accessModes = [ "ReadWriteOnce" ];
              storageClassName = "rbd-nvme";
              resources.requests.storage = "1Gi";
            };
          }];
          enableStatefulSetAutoDeletePVC = true;
        };

        alloy = {
          storagePath = "/var/lib/alloy";
          mounts.extra = [{ name = "storage"; mountPath = "/var/lib/alloy"; }];
          clustering.enabled = true;
          configMap.content = builtins.readFile ./alloy/config.alloy;
        };
      };

      includeCRDs = true;
    };
  };
}
