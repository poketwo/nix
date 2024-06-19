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

    helmReleases.trust-manager = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.jetstack.io";
        name = "trust-manager";
        version = "0.11.0";
        sha256 = "GdHwODmpDmk5osNzQ+v/OCXdvMEuyPsftHvOfgv3tfU=";
      };

      values = {
        secretTargets = {
          enabled = true;
          authorizedSecretsAll = true;
        };
      };
    };

    resources."cert-manager.io/v1".ClusterIssuer = {
      letsencrypt = leIssuer "letsencrypt" "https://acme-v02.api.letsencrypt.org/directory";
      letsencrypt-staging = leIssuer "letsencrypt-staging" "https://acme-staging-v02.api.letsencrypt.org/directory";
      selfsigned.spec.selfSigned = { };
      cluster-ca.spec.ca.secretName = "cluster-ca-secret";
    };

    resources."cert-manager.io/v1".Certificate.cluster-ca.spec = {
      isCA = true;
      commonName = "HFYM CA";
      secretName = "cluster-ca-secret";
      privateKey = {
        algorithm = "ECDSA";
        size = 256;
      };
      issuerRef = {
        name = "selfsigned";
        kind = "ClusterIssuer";
        group = "cert-manager.io";
      };
    };

    resources."trust.cert-manager.io/v1alpha1".Bundle.cluster-ca.spec = {
      sources = [{
        secret = {
          name = "cluster-ca-secret";
          key = "ca.crt";
        };
      }];
      target.secret.key = "ca.crt";
    };

    resources.v1.Secret.cloudflare-api-token = {
      type = "Opaque";
      stringData.token = "";
    };
  };
}
