{ lib, transpire, ... }:

let
  withEnv = obj: lib.mkMerge [
    obj
    {
      extraArgs = [ "-config.expand-env=true" ];
      extraEnvFrom = [{ secretRef.name = "backblaze-b2-credentials"; }];
    }
  ];
in
{
  namespaces.loki = {
    createNamespace = false;

    helmReleases.loki = {
      chart = transpire.fetchFromHelm {
        repo = "https://grafana.github.io/helm-charts";
        name = "loki";
        version = "6.6.3";
        sha256 = "lsfiXnoZRf8rSmAeyD5BzpPOEGdCj79hFxzmCa9ae6A=";
      };

      values = {
        loki = {
          schemaConfig = {
            configs = [{
              from = "2024-04-01";
              store = "tsdb";
              object_store = "s3";
              schema = "v13";
              index = { prefix = "loki_index_"; period = "24h"; };
            }];
          };
          ingester.chunk_encoding = "snappy";
          tracing.enabled = true;
          querier.max_concurrent = 4;
          storage = {
            type = "s3";
            bucketNames = {
              chunks = "hfym-loki-chunks";
              ruler = "hfym-loki-ruler";
              admin = "hfym-loki-admin";
            };
            s3 = {
              endpoint = "\${BUCKET_ENDPOINT}";
              accessKeyId = "\${AWS_ACCESS_KEY_ID}";
              secretAccessKey = "\${AWS_SECRET_ACCESS_KEY}";
            };
          };
        };

        loki.structuredConfig = {
          analytics.reporting_enabled = false;
          auth_enabled = false;
          common.ring.instance_enable_ipv6 = true;
          common.ring.kvstore.store = "memberlist";
          compactor.compactor_ring.instance_enable_ipv6 = true;
          compactor.compactor_ring.kvstore.store = "memberlist";
          distributor.ring.instance_enable_ipv6 = true;
          distributor.ring.kvstore.store = "memberlist";
          index_gateway.ring.instance_enable_ipv6 = true;
          index_gateway.ring.kvstore.store = "memberlist";
          ingester.lifecycler.enable_inet6 = true;
          ingester.lifecycler.ring.kvstore.store = "memberlist";
          query_scheduler.scheduler_ring.instance_enable_ipv6 = true;
          query_scheduler.scheduler_ring.kvstore.store = "memberlist";
          ruler.ring.kvstore.store = "memberlist";
          memberlist.bind_addr = [ "::" ];
        };

        deploymentMode = "SimpleScalable";

        backend = withEnv {
          replicas = 3;
          # resources = {
          #   limits = { memory = "4Gi"; };
          #   requests = { cpu = "100m"; memory = "128Mi"; };
          # };
        };

        read = withEnv {
          replicas = 3;
          # resources = {
          #   limits = { memory = "4Gi"; };
          #   requests = { cpu = "100m"; memory = "128Mi"; };
          # };
        };

        write = withEnv {
          replicas = 3;
          # resources = {
          #   limits = { memory = "4Gi"; };
          #   requests = { cpu = "100m"; memory = "128Mi"; };
          # };
        };

        minio.enabled = false;
        singleBinary.replicas = 0;
        ingester.replicas = 0;
        querier.replicas = 0;
        queryFrontend.replicas = 0;
        queryScheduler.replicas = 0;
        distributor.replicas = 0;
        compactor.replicas = 0;
        indexGateway.replicas = 0;
        bloomCompactor.replicas = 0;
        bloomGateway.replicas = 0;
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
