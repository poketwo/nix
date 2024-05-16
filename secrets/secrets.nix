let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    turtwig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWPy1tfPQ1xBAbD5f17E5vAtSWQsSVS5vYqgi93C6tt";
    chimchar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOgv5vkde1wAagmFl1cRlhPzC4uWb1orLKstEk//3r2i";
    piplup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnlP7RudQkxHUglGO+zxa/Owi2gW0JeILF59ksvgRpC";

    vaporeon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdnKsViSDqVa/taC7CGX7cSohCcw6RQEhj5AwLlwT2S";
    jolteon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAb/DNVpAqzP4xxVK/lOlhvMp1PpVaWs7CataJnSDCbz";
    flareon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9oJSfZOjijy1OVODHnx+e9BrKZdhGz8qIUoq14HO9f";
  };

  all-users = with users; [ oliver ];
  all-hosts = with hosts; [ turtwig chimchar piplup vaporeon jolteon flareon ];
in
{
  "tailscale-auth-key.age".publicKeys = all-users ++ all-hosts;
  "cloudflare-warp-mdm.xml.age".publicKeys = all-users ++ all-hosts;
}
