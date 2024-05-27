let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    turtwig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWPy1tfPQ1xBAbD5f17E5vAtSWQsSVS5vYqgi93C6tt";
    chimchar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOgv5vkde1wAagmFl1cRlhPzC4uWb1orLKstEk//3r2i";
    piplup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnlP7RudQkxHUglGO+zxa/Owi2gW0JeILF59ksvgRpC";

    vaporeon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIlJzVVwoQc1sPYr1fEWumBrIPKjKYvYORmarx0ofDV";
    jolteon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwnAVJa18Nvwpx8L1r4qG3jpRr1aAJN/4HjHHUCnkun";
    flareon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXAcViD+JS3KHgz2KYG6Q7g11UMyRh0IypAfvW5MYqN";
  };

  all-users = with users; [ oliver ];
  all-hosts = with hosts; [ turtwig chimchar piplup vaporeon jolteon flareon ];
in
{
  "tailscale-auth-key.age".publicKeys = all-users ++ all-hosts;
  "cloudflare-warp-mdm.xml.age".publicKeys = all-users ++ all-hosts;
}
