{ transpire, ... }:

let
  makeAffinity = componentName: {
    requiredDuringSchedulingIgnoredDuringExecution = [{
      labelSelector = {
        matchExpressions = [{
          key = "app.kubernetes.io/component";
          operator = "In";
          values = [ componentName ];
        }];
      };
      topologyKey = "kubernetes.io/hostname";
    }];
  };
in
{
  namespaces.mimir = {
    helmReleases.mimir = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "mimir-distributed";
        version = "5.3.0";
        sha256 = "REL6eOXlwHPROonlQ7/EfcM6mcvHXUDoM1O3eCsWu6o=";
      };

      values = {
        global.extraEnvFrom = [{
          secretRef.name = "backblaze-b2-credentials";
        }];

        mimir.structuredConfig = {
          usage_stats.enabled = false;
          alertmanager.sharding_ring.instance_enable_ipv6 = true;
          compactor.sharding_ring.instance_enable_ipv6 = true;
          distributor.ring.instance_enable_ipv6 = true;
          frontend.instance_enable_ipv6 = true;
          ingester.ring.instance_enable_ipv6 = true;
          ruler.ring.instance_enable_ipv6 = true;
          store_gateway.sharding_ring.instance_enable_ipv6 = true;
          memberlist.bind_addr = [ "::" ];

          common.storage = {
            backend = "s3";
            s3 = {
              endpoint = "\${BUCKET_ENDPOINT}";
              access_key_id = "\${AWS_ACCESS_KEY_ID}";
              secret_access_key = "\${AWS_SECRET_ACCESS_KEY}";
            };
          };

          blocks_storage.s3.bucket_name = "hfym-mimir-blocks";
          alertmanager_storage.s3.bucket_name = "hfym-mimir-alertmanager";
          ruler_storage.s3.bucket_name = "hfym-mimir-ruler";
        };

        alertmanager = {
          replicas = 2;
          resources = {
            limits = { memory = "1.4Gi"; };
            requests = { cpu = "1"; memory = "1Gi"; };
          };
        };

        compactor = {
          persistentVolume.size = "20Gi";
          resources = {
            limits = { memory = "2.1Gi"; };
            requests = { cpu = "1"; memory = "1.5Gi"; };
          };
        };

        distributor = {
          replicas = 2;
          resources = {
            limits = { memory = "5.7Gi"; };
            requests = { cpu = "2"; memory = "4Gi"; };
          };
        };

        ingester = {
          replicas = 3;
          persistentVolume.size = "50Gi";
          resources = {
            limits = { memory = "12Gi"; };
            requests = { cpu = "3.5"; memory = "8Gi"; };
          };
          affinity = makeAffinity "ingester";
          zoneAwareReplication.topologyKey = "kubernetes.io/hostname";
        };

        overrides_exporter = {
          resources = {
            limits = { memory = "128Mi"; };
            requests = { cpu = "100m"; memory = "128Mi"; };
          };
        };

        querier = {
          replicas = 1;
          resources = {
            limits = { memory = "5.6Gi"; };
            requests = { cpu = "2"; memory = "4Gi"; };
          };
        };

        query_frontend = {
          replicas = 1;
          resources = {
            limits = { memory = "2.8Gi"; };
            requests = { cpu = "2"; memory = "2Gi"; };
          };
        };

        ruler = {
          replicas = 1;
          resources = {
            limits = { memory = "2.8Gi"; };
            requests = { cpu = "1"; memory = "2Gi"; };
          };
        };

        store_gateway = {
          persistentVolume.size = "10Gi";
          replicas = 3;
          resources = {
            limits = { memory = "2.1Gi"; };
            requests = { cpu = "1"; memory = "1.5Gi"; };
          };
          affinity = makeAffinity "store-gateway";
          zoneAwareReplication.topologyKey = "kubernetes.io/hostname";
        };

        metadata-cache.enabled = true;
        chunks-cache.enabled = true;
        index-cache.enabled = true;
        results-cache.enabled = true;

        gateway.enabledNonEnterprise = true;

        nginx.enabled = false;
        minio.enabled = false;
      };
    };

    resources.v1.Secret."backblaze-b2-credentials" = {
      type = "Opaque";
      stringData = {
        BUCKET_ENDPOINT = "";
        AWS_ACCESS_KEY_ID = "";
        AWS_SECRET_ACCESS_KEY = "";
      };
    };
  };
}
