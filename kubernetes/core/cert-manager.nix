{ transpire, ... }:

let
  leIssuer = name: server: {
    spec.acme = {
      inherit server;
      email = "oliver@poketwo.net";
      privateKeySecretRef = { inherit name; };
      solvers = [{
        dns01.cloudflare.apiTokenSecretRef = {
          name = "cloudflare-api-token";
          key = "token";
        };
      }];
    };
  };
in
{
  namespaces.cert-manager = {
    helmReleases.cert-manager = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.jetstack.io";
        name = "cert-manager";
        version = "1.14.5";
        sha256 = "n6nMYkxAGabXoE/sGZsrCFnqm0dTzAqkITA83+FQ8o8=";
      };

      values = {
        installCRDs = true;
        global.leaderElection.namespace = "cert-manager";
        prometheus.enabled = true;
      };
    };

    resources."cert-manager.io/v1".ClusterIssuer = {
      letsencrypt = leIssuer "letsencrypt" "https://acme-v02.api.letsencrypt.org/directory";
      letsencrypt-staging = leIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
    };

    resources.v1.Secret."cloudflare-api-token" = {
      type = "Opaque";
      stringData.token = "";
    };
  };
}
