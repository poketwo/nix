let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    turtwig = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWPy1tfPQ1xBAbD5f17E5vAtSWQsSVS5vYqgi93C6tt";
    chimchar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOgv5vkde1wAagmFl1cRlhPzC4uWb1orLKstEk//3r2i";
    piplup = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnlP7RudQkxHUglGO+zxa/Owi2gW0JeILF59ksvgRpC";

    vaporeon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBIlJzVVwoQc1sPYr1fEWumBrIPKjKYvYORmarx0ofDV";
    jolteon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFtHLQC3dE3wS7qzp6vPYn6DGa5sWDCbOQMCKc+NaoZY";
    flareon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFHiJuP5fYnqHxAAMi/F1nwVA/zKw0zFazvxgsx9obqC";

    glaceon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhz8TgY7TI01qz7/5hIu6H36++ppJriNZfWySdDoMM1";
    sylveon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBle4/fnS9I41btk49rzY/EXuUNZkHthwprDhQr5ZUaW";
  };

  all-users = with users; [ oliver ];
  all-hosts = with hosts; [ turtwig chimchar piplup vaporeon jolteon flareon glaceon sylveon ];
in
{
  "tailscale-auth-key.age".publicKeys = all-users ++ all-hosts;
  "cloudflare-warp-mdm.xml.age".publicKeys = all-users ++ all-hosts;
  "jolteon-wireguard-private-key.age".publicKeys = all-users ++ [ hosts.jolteon ];
}
