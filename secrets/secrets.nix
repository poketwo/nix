let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    vaporeon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdnKsViSDqVa/taC7CGX7cSohCcw6RQEhj5AwLlwT2S";
    jolteon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAb/DNVpAqzP4xxVK/lOlhvMp1PpVaWs7CataJnSDCbz";
    flareon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oJSfZOjijy1OVODHnx+e9BrKZdhGz8qIUoq14HO9f";
  };

  all-users = with users; [ oliver ];
  all-hosts = with hosts; [ vaporeon jolteon flareon ];
in
{
  "tailscale-auth-key.age".publicKeys = all-users ++ all-hosts;
  "cloudflare-warp-mdm.xml.age".publicKeys = all-users ++ all-hosts;
}
