let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    turtwig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdnKsViSDqVa/taC7CGX7cSohCcw6RQEhj5AwLlwT2S";
    chimchar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAb/DNVpAqzP4xxVK/lOlhvMp1PpVaWs7CataJnSDCbz";
    piplup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oJSfZOjijy1OVODHnx+e9BrKZdhGz8qIUoq14HO9f";
  };

  all-users = with users; [ oliver ];
  all-hosts = with hosts; [ turtwig chimchar piplup ];
in
{
  "tailscale-auth-key.age".publicKeys = all-users ++ all-hosts;
}
