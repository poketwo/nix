{ transpire, ... }:

{
  namespaces.metallb = {
    helmReleases.metallb = {
      chart = transpire.fetchFromHelm {
        repo = "https://metallb.github.io/metallb";
        name = "metallb";
        version = "0.14.5";
        sha256 = "ZEyCi/F1JJP3kHZ6UzKT8K1YO3pB7h03iOIOvOmuenE=";
      };
    };

    resources."metallb.io/v1beta1" = {
      IPAddressPool.isogram-ipv6.spec.addresses = [ "2606:c2c0:5:1:3::/112" ];

      L2Advertisement.isogram.spec = {
        ipAddressPools = [ "isogram-ipv6" ];
        nodeSelectors = [
          # We don't want to announce Isogram IPs from Linode control plane
          { matchLabels."kubernetes.io/hostname" = "vaporeon"; }
          { matchLabels."kubernetes.io/hostname" = "jolteon"; }
          { matchLabels."kubernetes.io/hostname" = "flareon"; }
        ];
      };
    };
  };
}
