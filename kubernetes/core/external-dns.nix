{ transpire, ... }:

{
  namespaces.external-dns = {
    helmReleases.external-dns = {
      chart = transpire.fetchFromHelm {
        repo = "https://kubernetes-sigs.github.io/external-dns/";
        name = "external-dns";
        version = "1.14.4";
        sha256 = "Fn16uvOUGuzGwEu29ngy2uM09ttKCfNVdqRnEpiOi/g=";
      };
      values = {
        provider.name = "cloudflare";
        env = [{
          name = "CF_API_TOKEN";
          valueFrom.secretKeyRef = { name = "cloudflare-api-token"; key = "token"; };
        }];
        extraArgs = [
          "--domain-filter=hfym.co"
          "--domain-filter=poketwo.io"
          "--domain-filter=poketwo.net"
          "--domain-filter=berkeley.mt"
          "--domain-filter=contestdojo.com"
          "--cloudflare-proxied"
        ];
        policy = "sync";
      };
    };

    resources.v1.Secret."cloudflare-api-token" = {
      type = "Opaque";
      stringData.token = "";
    };
  };
}
