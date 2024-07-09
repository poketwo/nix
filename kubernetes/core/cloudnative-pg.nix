{ transpire, ... }:

{
  namespaces.cloudnative-pg = {
    helmReleases.cloudnative-pg = {
      chart = transpire.fetchFromHelm {
        repo = "https://cloudnative-pg.github.io/charts";
        name = "cloudnative-pg";
        version = "0.21.5";
        sha256 = "k8Z1QrcdE+EjRfhhv5dlvJV7KNDc6FTQAqHTG1C7LLM=";
      };
    };
  };
}
