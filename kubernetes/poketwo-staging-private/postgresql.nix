{ ... }:

{
  namespaces.poketwo-staging-private.resources = {
    # =========================
    # PostgreSQL Cluster (CNPG)
    # =========================

    "postgresql.cnpg.io/v1".Cluster.poketwo-postgres.spec = {
      instances = 2; # Smaller for staging
      imageName = "ghcr.io/cloudnative-pg/postgresql:16.4";

      bootstrap.initdb = {
        database = "poketwo";
        owner = "poketwo";
        postInitSQL = [
          "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
          "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
        ];
      };

      storage = {
        size = "20Gi";
        storageClass = "rbd-nvme-retain";
      };

      walStorage = {
        size = "5Gi";
        storageClass = "rbd-nvme-retain";
      };

      resources = {
        requests = { cpu = "100m"; memory = "1Gi"; };
        limits = { memory = "4Gi"; };
      };

      postgresql.parameters = {
        shared_buffers = "512MB";
        effective_cache_size = "2GB";
        work_mem = "32MB";
        maintenance_work_mem = "256MB";
        max_connections = "100";
        log_min_duration_statement = "500";
      };

      monitoring.enablePodMonitor = true;
    };

    # PgBouncer pooler (single instance for staging)
    "postgresql.cnpg.io/v1".Pooler.poketwo-pgbouncer-rw.spec = {
      cluster.name = "poketwo-postgres";
      instances = 1;
      type = "rw";
      pgbouncer = {
        poolMode = "transaction";
        parameters = {
          max_client_conn = "200";
          default_pool_size = "20";
        };
      };
      template.spec.resources = {
        requests = { cpu = "50m"; memory = "128Mi"; };
        limits = { memory = "256Mi"; };
      };
    };
  };
}
