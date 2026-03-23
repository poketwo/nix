{ ... }:

{
  namespaces.poketwo = {
    resources = {
      # =========================
      # PostgreSQL Cluster (CNPG)
      # =========================

      "postgresql.cnpg.io/v1".Cluster.poketwo-postgres.spec = {
        # 1 primary + 2 read replicas for HA
        instances = 3;

        # PostgreSQL 16
        imageName = "ghcr.io/cloudnative-pg/postgresql:16.4";

        # Bootstrap configuration
        bootstrap.initdb = {
          database = "poketwo";
          owner = "poketwo";
          postInitSQL = [
            "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
            "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
          ];
        };

        # Data storage — 4.9B rows × ~500 bytes ≈ 2.45TB + indexes + overhead
        storage = {
          size = "3Ti";
          storageClass = "rbd-nvme-retain";
        };

        # Separate WAL storage for better write performance
        walStorage = {
          size = "100Gi";
          storageClass = "rbd-nvme-retain";
        };

        # Resource limits
        resources = {
          requests = { cpu = "4000m"; memory = "64Gi"; };
          limits = { memory = "120Gi"; };
        };

        # PostgreSQL configuration tuned for NVMe + 4.9B rows
        postgresql.parameters = {
          # Memory
          shared_buffers = "32GB";
          effective_cache_size = "96GB";
          work_mem = "256MB";
          maintenance_work_mem = "4GB";

          # WAL
          wal_buffers = "64MB";
          max_wal_size = "8GB";
          min_wal_size = "1GB";

          # Query planner (NVMe-optimized)
          random_page_cost = "1.1";
          effective_io_concurrency = "200";

          # Parallelism
          max_parallel_workers_per_gather = "4";
          max_parallel_workers = "8";
          max_parallel_maintenance_workers = "4";

          # Connections (PgBouncer handles pooling)
          max_connections = "300";

          # Logging
          log_min_duration_statement = "1000";
          log_checkpoints = "on";
          log_lock_waits = "on";

          # Autovacuum (critical for large tables)
          autovacuum_max_workers = "6";
          autovacuum_naptime = "30s";
          autovacuum_vacuum_cost_limit = "2000";

          # Stats
          "pg_stat_statements.track" = "all";
        };

        # Monitoring — exposes /metrics for Prometheus
        monitoring.enablePodMonitor = true;

        # Backup configuration (Backblaze B2)
        backup = {
          barmanObjectStore = {
            destinationPath = "s3://hfym-pg-backups/poketwo/";
            endpointURL = "https://s3.us-west-000.backblazeb2.com";
            s3Credentials = {
              accessKeyId = { name = "postgresql-backup-credentials"; key = "ACCESS_KEY_ID"; };
              secretAccessKey = { name = "postgresql-backup-credentials"; key = "SECRET_ACCESS_KEY"; };
            };
          };
          retentionPolicy = "30d";
        };
      };

      # ================
      # Scheduled Backup
      # ================

      "postgresql.cnpg.io/v1".ScheduledBackup.poketwo-postgres-backup.spec = {
        schedule = "0 0 3 * * *"; # Daily at 3 AM UTC
        cluster.name = "poketwo-postgres";
        backupOwnerReference = "self";
      };

      # ===============================
      # PgBouncer — Read/Write Pooler
      # ===============================

      "postgresql.cnpg.io/v1".Pooler.poketwo-pgbouncer-rw.spec = {
        cluster.name = "poketwo-postgres";
        instances = 3;
        type = "rw";
        pgbouncer = {
          poolMode = "transaction";
          parameters = {
            max_client_conn = "2000";
            default_pool_size = "50";
            reserve_pool_size = "10";
            reserve_pool_timeout = "3";
            server_idle_timeout = "300";
            query_wait_timeout = "60";
          };
        };
        template.spec.resources = {
          requests = { cpu = "100m"; memory = "256Mi"; };
          limits = { memory = "512Mi"; };
        };
      };

      # =============================
      # PgBouncer — Read-Only Pooler
      # =============================

      "postgresql.cnpg.io/v1".Pooler.poketwo-pgbouncer-ro.spec = {
        cluster.name = "poketwo-postgres";
        instances = 2;
        type = "ro";
        pgbouncer = {
          poolMode = "transaction";
          parameters = {
            max_client_conn = "1000";
            default_pool_size = "30";
          };
        };
        template.spec.resources = {
          requests = { cpu = "100m"; memory = "256Mi"; };
          limits = { memory = "512Mi"; };
        };
      };

      # ==================
      # Backup Credentials
      # ==================

      v1.Secret."postgresql-backup-credentials" = {
        type = "Opaque";
        stringData = {
          ACCESS_KEY_ID = "";
          SECRET_ACCESS_KEY = "";
        };
      };
    };
  };
}
