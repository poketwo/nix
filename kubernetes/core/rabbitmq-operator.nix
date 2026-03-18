{ transpire, ... }:

{
  namespaces.rabbitmq-operator = {
    helmReleases.rabbitmq-operator = {
      chart = transpire.fetchFromHelm {
        repo = "https://charts.bitnami.com/bitnami";
        name = "rabbitmq-cluster-operator";
        version = "4.3.18";
        sha256 = "8QwU58eWyWPIU2Xy4Z1Vx6TOf+CQRtjIOTx22EI4Nik=";
      };

      values = {
        global.imageRegistry = "docker.io";
        global.security.allowInsecureImages = true;
        rabbitmqImage.repository = "bitnamilegacy/rabbitmq";
        credentialUpdaterImage.repository = "bitnamilegacy/rmq-default-credential-updater";
        clusterOperator = {
          networkPolicy.enabled = false;
          image.repository = "bitnamilegacy/rabbitmq-cluster-operator";
        };
        msgTopologyOperator = {
          networkPolicy.enabled = false;
          image.repository = "bitnamilegacy/rmq-messaging-topology-operator";
        };
      };

      includeCRDs = true;
    };
  };
}
