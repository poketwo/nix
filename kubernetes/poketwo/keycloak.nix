{ transpire, ... }:

let
  downloadResources = ''
    mkdir -p /keycloak/providers /keycloak/themes/keywind \
    && wget -nc -O /keycloak/providers/keycloak-discord-0.4.0.jar \
      https://github.com/wadahiro/keycloak-discord/releases/download/v0.4.1/keycloak-discord-0.4.1.jar \
    && (git -C /keycloak/themes/keywind pull || git clone https://github.com/lukin/keywind /keycloak/themes/keywind)
  '';

  keycloakConfigCli = {
    realm = "poketwo";
    displayName = "Pokétwo";
    ssoSessionIdleTimeout = 2592000;
    ssoSessionMaxLifespan = 2592000;
    offlineSessionIdleTimeout = 2592000;
    enabled = true;
    sslRequired = "all";
    registrationAllowed = false;
    loginTheme = "keywind";
    accountTheme = "keycloak.v2";
    adminTheme = "keycloak.v2";
    emailTheme = "keycloak";
    clients = [
      {
        clientId = "google.com";
        name = "Google Workspace";
        clientAuthenticatorType = "client-secret";
        redirectUris = [ "https://www.google.com/*" ];
        protocol = "saml";
        enabled = true;
        attributes = {
          saml_name_id_format = "email";
          "saml.server.signature" = "false";
          "saml.client.signature" = "false";
          "saml.assertion.signature" = "true";
        };
      }
      {
        clientId = "guiduck";
        name = "Guiduck";
        clientAuthenticatorType = "client-secret";
        publicClient = false;
        protocol = "openid-connect";
        standardFlowEnabled = false;
        enabled = true;
      }
      {
        clientId = "outline.poketwo.io";
        name = "Outline";
        redirectUris = [ "https://outline.poketwo.io/auth/oidc.callback" ];
        clientAuthenticatorType = "client-secret";
        publicClient = false;
        protocol = "openid-connect";
        enabled = true;
      }
    ];

    # Override this to turn creating users off
    authenticationFlows = [
      {
        alias = "User creation or linking";
        description = "Flow for the existing/non-existing user alternatives";
        providerId = "basic-flow";
        topLevel = false;
        builtIn = true;
        authenticationExecutions = [
          {
            authenticatorConfig = "create unique user config";
            authenticator = "idp-create-user-if-unique";
            authenticatorFlow = false;
            requirement = "DISABLED";
            priority = 10;
            autheticatorFlow = false;
            userSetupAllowed = false;
          }
          {
            authenticatorFlow = true;
            requirement = "ALTERNATIVE";
            priority = 20;
            autheticatorFlow = true;
            flowAlias = "Handle Existing Account";
            userSetupAllowed = false;
          }
        ];
      }
      {
        alias = "first broker login";
        description = "Actions taken after first broker login with identity provider account, which is not yet linked to any Keycloak account";
        providerId = "basic-flow";
        topLevel = true;
        builtIn = true;
        authenticationExecutions = [
          {
            authenticatorConfig = "review profile config";
            authenticator = "idp-review-profile";
            authenticatorFlow = false;
            requirement = "DISABLED";
            priority = 10;
            autheticatorFlow = false;
            userSetupAllowed = false;
          }
          {
            authenticatorFlow = true;
            requirement = "REQUIRED";
            priority = 20;
            autheticatorFlow = true;
            flowAlias = "User creation or linking";
            userSetupAllowed = false;
          }
        ];
      }
    ];
  };
in
{
  namespaces.keycloak = {
    helmReleases.keycloak = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "keycloak";
        version = "21.6.1";
        sha256 = "0K1kGpPLchgevJ69KUwoLHrtE1vdoy3m8RZNMIKZjZ0=";
      };

      values = {
        global.imageRegistry = "docker.io/bitnamilegacy";
        auth.existingSecret = "keycloak-auth";
        production = true;
        proxy = "edge";
        replicaCount = 1;
        metrics.enabled = true;
        postgresql.enabled = false;
        networkPolicy.enabled = false;

        initContainers = [{
          name = "download-resources";
          image = "alpine/git";
          command = [ "/bin/sh" "-c" ];
          args = [ downloadResources ];
          volumeMounts = [{ name = "keycloak"; mountPath = "/keycloak"; }];
        }];

        ingress = {
          enabled = true;
          annotations."cert-manager.io/cluster-issuer" = "letsencrypt";
          hostname = "auth-dev.poketwo.io";
          tls = true;
        };

        externalDatabase = {
          host = "keycloak-postgres-rw";
          port = 5432;
          user = "keycloak";
          database = "keycloak";
          existingSecret = "keycloak-postgres-app";
          existingSecretPasswordKey = "password";
        };

        extraVolumes = [{
          name = "keycloak";
          persistentVolumeClaim = { claimName = "keycloak"; };
        }];

        extraVolumeMounts = [
          {
            mountPath = "/opt/bitnami/keycloak/providers/keycloak-discord-0.4.0.jar";
            name = "keycloak";
            subPath = "providers/keycloak-discord-0.4.0.jar";
          }
          {
            mountPath = "/opt/bitnami/keycloak/themes/keywind";
            name = "keycloak";
            subPath = "themes/keywind/theme/keywind";
          }
        ];

        keycloakConfigCli = {
          enabled = true;
          existingConfigmap = "keycloak-config-cli";
          cleanupAfterFinished.enabled = true;
        };
      };
    };

    resources = {
      "postgresql.cnpg.io/v1".Cluster.keycloak-postgres.spec = {
        instances = 3;
        bootstrap.initdb.database = "keycloak";
        storage.size = "8Gi";
      };

      v1.PersistentVolumeClaim.keycloak.spec = {
        accessModes = [ "ReadWriteOnce" ];
        resources.requests.storage = "2Gi";
      };

      v1.Secret.keycloak-auth.stringData = {
        admin-password = "";
      };

      v1.ConfigMap.keycloak-config-cli.data = {
        configuration = builtins.toJSON keycloakConfigCli;
      };
    };
  };
}
