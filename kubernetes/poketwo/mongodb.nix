{ lib, transpire, ... }:

let
  requireHostname = hostname: {
    required.nodeSelectorTerms = [{
      matchExpressions = [{
        key = "kubernetes.io/hostname";
        operator = "In";
        values = [ hostname ];
      }];
    }];
  };

  datadirPv = hostname: {
    metadata.labels."velero.io/exclude-from-backup" = "true";
    spec = {
      capacity.storage = "2Ti";
      volumeMode = "Filesystem";
      accessModes = [ "ReadWriteOnce" ];
      persistentVolumeReclaimPolicy = "Retain";
      storageClassName = "manual";
      local.path = "/mongo";
      nodeAffinity = requireHostname hostname;
    };
  };

  datadirPvcSpec = pvName: {
    storageClassName = "manual";
    accessModes = [ "ReadWriteOnce" ];
    resources.requests.storage = "2Ti";
    volumeName = pvName;
  };
in
{
  namespaces.poketwo = {
    helmReleases.mongodb = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "mongodb";
        version = "15.6.12";
        sha256 = "HfgOlkMxIFSE7x1d8y2cMaT91YAfUAKkijlINZEcsPY=";
      };

      values = {
        architecture = "replicaset";
        auth = { enabled = true; existingSecret = "mongodb"; };
        replicaSetName = "poketwo";
        replicaSetHostnames = true;
        replicaCount = 2;
        enableIPv6 = true;

        resources = {
          limits = { memory = "80Gi"; };
          requests = { cpu = "6000m"; memory = "60Gi"; };
        };
        persistence = { enabled = true; size = "2Ti"; };

        rbac.create = true;
        serviceAccount.automountServiceAccountToken = true;
        automountServiceAccountToken = true;
        serviceAccount.create = true;

        externalAccess = {
          enabled = true;
          autoDiscovery.enabled = true;

          service = {
            annotations."external-dns.alpha.kubernetes.io/cloudflare-proxied" = "false";
            annotationsList = [
              { "external-dns.alpha.kubernetes.io/hostname" = "mongodb-0-external.poketwo.ds.hfym.co"; }
              { "external-dns.alpha.kubernetes.io/hostname" = "mongodb-1-external.poketwo.ds.hfym.co"; }
            ];
            type = "LoadBalancer";
            ports.mongodb = 27017;
          };
        };

        arbiter = {
          enabled = true;
          resources = {
            limits = { memory = "2Gi"; };
            requests = { cpu = "100m"; memory = "2Gi"; };
          };
        };

        volumePermissions.enabled = true;
        metrics.enabled = true;
      };
    };

    resources = {
      v1.PersistentVolume.datadir-mongodb-0 = datadirPv "vaporeon";
      v1.PersistentVolume.datadir-mongodb-1 = datadirPv "jolteon";

      v1.PersistentVolumeClaim.datadir-mongodb-0.spec = datadirPvcSpec "datadir-mongodb-0";
      v1.PersistentVolumeClaim.datadir-mongodb-1.spec = datadirPvcSpec "datadir-mongodb-1";

      v1.Secret.mongodb.stringData = {
        mongodb-replica-set-key = "";
        mongodb-root-password = "";
      };
    };
  };

  transforms =
    let
      fixStupidThing = { apiVersion, kind, metadata, ... }@obj:
        if apiVersion == "apps/v1" && kind == "StatefulSet" && metadata.name == "mongodb" && metadata.namespace == "poketwo" then
          obj // {
            spec = obj.spec // {
              template = obj.spec.template // {
                spec = obj.spec.template.spec // {
                  initContainers =
                    map
                      (lib.filterAttrs (name: _: name != "automountServiceAccountToken"))
                      obj.spec.template.spec.initContainers;
                };
              };
            };
          }
        else obj;
    in
    [ fixStupidThing ];
}
