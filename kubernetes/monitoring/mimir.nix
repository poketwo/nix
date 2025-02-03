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

          limits.max_global_series_per_user = 2000000;
          blocks_storage.s3.bucket_name = "hfym-mimir-blocks";
          alertmanager_storage.s3.bucket_name = "hfym-mimir-alertmanager";
          ruler_storage.s3.bucket_name = "hfym-mimir-ruler";
        };

        alertmanager = {
          replicas = 2;
          resources = {
            limits = { memory = "500Mi"; };
            requests = { cpu = "50m"; memory = "50Mi"; };
          };
        };

        compactor = {
          persistentVolume.size = "500Mi";
          resources = {
            limits = { memory = "2.1Gi"; };
            requests = { cpu = "50m"; memory = "50Mi"; };
          };
        };

        distributor = {
          replicas = 2;
          resources = {
            limits = { memory = "1Gi"; };
            requests = { cpu = "50m"; memory = "100Mi"; };
          };
        };

        ingester = {
          replicas = 3;
          persistentVolume.size = "2Gi";
          resources = {
            limits = { memory = "12Gi"; };
            requests = { cpu = "200m"; memory = "300Mi"; };
          };
          affinity = makeAffinity "ingester";
          zoneAwareReplication.topologyKey = "kubernetes.io/hostname";
        };

        overrides_exporter = {
          resources = {
            limits = { memory = "128Mi"; };
            requests = { cpu = "50m"; memory = "128Mi"; };
          };
        };

        querier = {
          replicas = 1;
          resources = {
            limits = { memory = "2Gi"; };
            requests = { cpu = "100m"; memory = "200Mi"; };
          };
        };

        query_frontend = {
          replicas = 1;
          resources = {
            limits = { memory = "2Gi"; };
            requests = { cpu = "100m"; memory = "200Mi"; };
          };
        };

        ruler = {
          replicas = 1;
          resources = {
            limits = { memory = "500Mi"; };
            requests = { cpu = "50m"; memory = "50Mi"; };
          };
        };

        store_gateway = {
          persistentVolume.size = "10Gi";
          replicas = 3;
          resources = {
            limits = { memory = "500Mi"; };
            requests = { cpu = "50m"; memory = "50Mi"; };
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
