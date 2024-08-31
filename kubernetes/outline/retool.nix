{ transpire, ... }:

{
  namespaces.retool = {
    helmReleases.retool = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.retool.com";
        name = "retool";
        version = "6.0.2";
        sha256 = "Gp2Zyffq9eDHPKIj2nznW4sEBqzZV8cFOmDRjeQwau0=";
      };

      values = {
        image = {
          repository = "tryretool/backend";
          tag = "3.75.1-stable";
        };

        config = {
          useInsecureCookies = false;
          licenseKeySecretName = "retool";
          encryptionKeySecretName = "retool";
          jwtSecretSecretName = "retool";
          auth.google = {
            clientId = "997504863600-6nfvs9g5cbtovgnfjpq50h6r3p7jnr2l.apps.googleusercontent.com";
            clientSecretSecretName = "retool";
            domain = "poketwo.net";
          };
          postgresql = {
            host = "postgres-rw";
            port = 5432;
            db = "retool";
            user = "retool";
            ssl_enabled = true;
            passwordSecretName = "postgres-app";
            passwordSecretKey = "password";
          };
        };

        ingress = {
          enabled = true;
          annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
          hosts = [{
            host = "retool.poketwo.io";
            paths = [{ path = "/"; }];
          }];
          tls = [{
            hosts = [ "retool.poketwo.io" ];
            secretName = "retool-ingress-tls";
          }];
        };

        postgresql.enabled = false;
        persistentVolumeClaim.enabled = false;
        env.DEFAULT_GROUP_FOR_DOMAINS = "poketwo.net -> all-users";
      };
    };

    resources."postgresql.cnpg.io/v1".Cluster.postgres.spec = {
      instances = 3;
      bootstrap.initdb.database = "retool";
      storage.size = "8Gi";
    };

    resources.v1.Secret.retool.stringData = {
      encryption-key = "";
      google-client-secret = "";
      jwt-secret = "";
      license-key = "";
    };
  };
}
