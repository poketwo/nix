{ transpire, ... }:

{
  namespaces.vault-secrets-operator.helmReleases.vault-secrets-operator = {
    chart = transpire.fetchFromHelm {
      repo = "https://helm.releases.hashicorp.com";
      name = "vault-secrets-operator";
      version = "0.7.0";
      sha256 = "eUZTE+tuag3qwIpozu9Fd72F7kpDVOdEydsEe+Z4v4Y=";
    };

    values = {
      defaultVaultConnection = {
        enabled = true;
        address = "http://vault.vault.svc.cluster.local:8200";
      };
      defaultAuthMethod = {
        enabled = true;
        kubernetes.role = "vault-secrets-operator";
      };
      tests.enabled = false;
    };

    includeCRDs = true;
  };
}
