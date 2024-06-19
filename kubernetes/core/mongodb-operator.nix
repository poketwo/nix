{ transpire, ... }:

{
  namespaces.mongodb-operator = {
    helmReleases.mongodb-operator = {
      chart = transpire.fetchFromHelm {
        repo = "https://mongodb.github.io/helm-charts";
        name = "community-operator";
        version = "0.9.0";
        sha256 = "OvHPiqHinxSD7vYtYKlfuvgNjG6+6jLZwIlpvFvMOZ8=";
      };

      values = {
        operator.watchNamespace = "*";
      };
    };
  };
}
