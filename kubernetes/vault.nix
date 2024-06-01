{ transpire, ... }:

{
  namespaces.vault.helmReleases.vault = {
    chart = transpire.fetchFromHelm {
      repo = "https://helm.releases.hashicorp.com";
      name = "vault";
      version = "0.28.0";
      sha256 = "vHAfKrM7XxyRMjmUspjTkCFUWwQu04NuMkJg7vUX9gY=";
    };

    values = {
      server = {
        auditStorage.enabled = true;
        standalone.enabled = false;

        ha = {
          enabled = true;
          replicas = 3;

          raft = {
            enabled = true;
            setNodeId = true;
            config = ''
              ui = true

              listener "tcp" {
                tls_disable = 1
                address = "[::]:8200"
                cluster_address = "[::]:8201"
                telemetry { unauthenticated_metrics_access = "true" }
              }

              storage "raft" {
                path = "/vault/data"
                retry_join { leader_api_addr = "http://vault-0.vault-internal:8200" }
                retry_join { leader_api_addr = "http://vault-1.vault-internal:8200" }
                retry_join { leader_api_addr = "http://vault-2.vault-internal:8200" }
              }

              service_registration "kubernetes" {}
            '';
          };
        };
      };

      ui.enabled = true;
    };
  };
}
