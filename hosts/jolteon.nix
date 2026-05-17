{ config, ... }:

{
  imports = [
    ../hardware/jolteon.nix
  ];

  boot.loader.systemd-boot.enable = true;

  networking = {
    hostName = "jolteon";
    hostId = "b113ba8f";
  };

  poketwo.network = {
    enable = true;
    interfaces = [ "enp193s0f0np0" "enp193s0f1np1" ];
    lastOctet = 129;
  };

  poketwo.kubernetes.enable = true;

  boot.zfs.extraPools = [ "mongo" ];
  fileSystems."/mongo" = {
    device = "/dev/zvol/mongo/mongo";
    fsType = "xfs";
  };

  # WIREGUARD

  age.secrets.jolteon-wireguard-private-key = {
    file = ../secrets/jolteon-wireguard-private-key.age;
    mode = "640";
    group = "systemd-network";
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

  systemd.network = {
    netdevs."99-wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
      };
      wireguardConfig = {
        PrivateKeyFile = config.age.secrets.jolteon-wireguard-private-key.path;
        ListenPort = 51820;
      };
      wireguardPeers =
        let makePeer = PublicKey: AllowedIPs: { inherit PublicKey AllowedIPs; }; in
        [
          (makePeer "0MKg6eKw1kYQ7dUxVscd8sgggU5po3jBsw4JK1nwli8=" [ "10.0.0.2/32" ]) # macbook
          (makePeer "54txYKQXU1Vta8Ppl+P5KL76HzoVo+wmbGqNFNdeMiY=" [ "10.0.0.3/32" ]) # phone

          (makePeer "8uJWTgTzFEi/FX+TY8ofTg9nKgUgV3P3Q3yl/qpdaXA=" [ "10.0.1.0/32" ]) # Timothe
          (makePeer "bl9m12yX5HnkCDFoSYy4FSN8FNUb0DYLBhPZI22a0Xs=" [ "10.0.1.1/32" ]) # Moor
          (makePeer "l8862KqO5jPTj/HAF9P3d2K0EoatxvMDURITMrI0iyQ=" [ "10.0.1.2/32" ]) # Moor
          (makePeer "lv/Rnyw8i02x+rp6q6tRVVszkgkXvUjjzUZVHH56ync=" [ "10.0.1.3/32" ]) # Timothe
          (makePeer "ZyCHH1CPzMYZxAHmFOHnMLkVGx8zJ8BfjOHP3uwilTQ=" [ "10.0.1.4/32" ]) # Landrew
          (makePeer "anb8+nRibNtMsQiNMKBd4i43o7aC1yMJuAVYdnPgIzs=" [ "10.0.1.5/32" ]) # Landrew
          (makePeer "PVos0SA2I/PtbwU7DcEILixafC5/vvmzLl6mEPC/aEk=" [ "10.0.1.6/32" ]) # Clara
          (makePeer "6okvKPUUj0bNd32lTq99bzxiX2A2rXFF47puNqQOozU=" [ "10.0.1.7/32" ]) # Clara
          (makePeer "3dN6v6LGpGYkka1mRW0XiZNPyNxvGXEDRM7N2H6vPFY=" [ "10.0.1.8/32" ]) # Sabine
          (makePeer "V2Ftux68Fm87u70wQ92V0rGNRprPKdqf56khMii/hHU=" [ "10.0.1.9/32" ]) # Sabine
          (makePeer "2lgbJAcNghipThAacQUX+GaKJ0F3zvZLXiIV7iZWWhM=" [ "10.0.1.10/32" ]) # Mary
          (makePeer "xdo0B3RLN2gPOb1LoDnzQofUkPzaNpifmGfoVPY8eks=" [ "10.0.1.11/32" ]) # Mary
          (makePeer "Hn3lhneJQiv9KHPJp2KIY1O783EY0Nl0sNzu4YK4fSY=" [ "10.0.1.12/32" ]) # Jonathan
          (makePeer "21QfQXFUXUcYFmwwXHF/Clg2+/8ohmh0ozYTQkNsNQc=" [ "10.0.1.13/32" ]) # Jonathan
          (makePeer "2SNBdiLynHBiz5S1J70aWp2bJeCBwR36Xw5yD386Gmc=" [ "10.0.1.14/32" ]) # Benji
          (makePeer "KKxE9JKRGJ+5Jj4Ym1NFgt+JO9kHeX9Bd0hWCakVMEA=" [ "10.0.1.15/32" ]) # Benji
          (makePeer "+EiEzK4On5BrNkcP1IcGNeToXudRpDhEl5lJm1stn2M=" [ "10.0.1.16/32" ]) # Ylann
          (makePeer "+Yq61rAePR5LnNz7rN1IKf2EMACm6lawUngoopN4lgs=" [ "10.0.1.17/32" ]) # Ylann
          (makePeer "SN7GxfbGWuubPS+GPnnGjBVeYFgfVR1iqfV8awix2jc=" [ "10.0.1.18/32" ]) # Isaac
          (makePeer "/dEuzFkp1H1FySX/NwOAI+K3FqEPOZK/CjuRoZQymHI=" [ "10.0.1.19/32" ]) # Isaac
          (makePeer "je1/ZqP5k8SGlzrTjQT6+mWJ/5XveOomikAbNe/5nEQ=" [ "10.0.1.20/32" ]) # Rohit
          (makePeer "MpNvkU3pjJ30r3pmy4jlH5OBlB7IsFvNdYIJTDHNv0E=" [ "10.0.1.21/32" ]) # Rohit
          (makePeer "osossFrXtubHNRXwQaWjEGYE92LhQHBAhawTKSZBhwY=" [ "10.0.1.22/32" ]) # Daisy
          (makePeer "oBzJ+jbeXPgn/PfZ1mJzKqBS6T5Tgzg5XPTU0vvyHSA=" [ "10.0.1.23/32" ]) # Daisy
          (makePeer "tlNmIi8/YOxhYKlj1C/Np2qLXYdS2Fl3gnxPhoHgYQI=" [ "10.0.1.24/32" ]) # Mom
          (makePeer "u3vC0cCk/Tewx8L4NDAsKt7YAmLqp/5YuzKSr2DBDDI=" [ "10.0.1.25/32" ]) # Mom
          (makePeer "ZPYYdjejpPBxya6zZsstIwrdOASIPjtsKX4Kh/MmgzI=" [ "10.0.1.26/32" ]) # Viraj
          (makePeer "gkug2F5Jz9enIRX2BdCKajerbRNkCppCE7P+gZU74R4=" [ "10.0.1.27/32" ]) # Viraj
          (makePeer "rxF5WaJ4u5TaXUpxM1B24l8SYY8FOe9Df0jzWTwcJRo=" [ "10.0.1.28/32" ]) # Carlyana
          (makePeer "8PoySfifjM8fx9pPTDzr1bPHsrmZQEXAVUVQ0yOisCU=" [ "10.0.1.29/32" ]) # Carlyana
          (makePeer "Ie5R/dhbo2XL2FKEy8IXiR/+s19+3GADnA2xY7pJ4RQ=" [ "10.0.1.30/32" ]) # Aarush
          (makePeer "lVzDxAgX+/yQXt/49PKaacxs9z9cTmCtGd1DpKhC9i0=" [ "10.0.1.31/32" ]) # Aarush
          (makePeer "GiMhUPXnCu8V+d3bg9RF7qG9JcMLUppy9yPH/6Gr6zo=" [ "10.0.1.32/32" ]) # Theo
          (makePeer "luO/YxGwamUltBvaI8FP5phwrjxCD5EV8ElC9FaNSn4=" [ "10.0.1.33/32" ]) # Theo
          (makePeer "flEgvGvdQBu8CSluOPpai78AiV+nfqMC9KZAzoMbtDw=" [ "10.0.1.34/32" ]) # Jeslyn
          (makePeer "nx70v5IqLltD60pYsB36RGNG/y7KK2/VgFg/vj+tBDI=" [ "10.0.1.35/32" ]) # Jeslyn
          (makePeer "ISWSb+SZawyr41q969VdkOBjrig4Bk6dA9ciI6VA7iI=" [ "10.0.1.36/32" ]) # Yuxuan
          (makePeer "HcZOGKGM+sfUC23r8yMi8RpDN+VyPyr3/nwVs0BZnAs=" [ "10.0.1.37/32" ]) # Yuxuan
          (makePeer "/FVOLkqOWZ/7GnK/RiZVht3xYbkLLaZY3uvf0r8grE0=" [ "10.0.1.38/32" ]) # Handrew
          (makePeer "ef08SkM6wKX9LoN6qAf0+xGh0VB4sRErIc5EdXi2IXQ=" [ "10.0.1.39/32" ]) # Handrew
          (makePeer "gAwa2DUy1BtQCUYRymiQ1u1VLD551m6QKStJRuSeIAs=" [ "10.0.1.40/32" ]) # Golden
          (makePeer "uGtKS8SW9+PUkGN+XNyDioAdrTiY2U4cwF87BWF+IQc=" [ "10.0.1.41/32" ]) # Golden
          (makePeer "aG+gFvE2r66YfSvVfFH6JbMMVNHZxhWhEYb08mICABw=" [ "10.0.1.42/32" ]) # aedan
          (makePeer "pqqM7hvravuUdAGPDbrsCGKA7bNqKEJHLg6BKFySgV0=" [ "10.0.1.43/32" ]) # aedan
          (makePeer "Zdi9i/9Htah72v769z9emk0aUOGkCPKWiAHc1hf2iEc=" [ "10.0.1.44/32" ]) # dario
          (makePeer "cYTQkYg278wXY03QJggpi7liwF+fKwF6YZokTHVaMG0=" [ "10.0.1.45/32" ]) # dario
          (makePeer "O4NekwQ/VUD+Pqq/68OdMFZISFkweC4RawtM2RpAnRM=" [ "10.0.1.46/32" ]) # harsh
          (makePeer "o2/FkQB+6PyYV7XXxtKeuj0cFu/gSvPxRfOoU/8aam0=" [ "10.0.1.47/32" ]) # harsh
          (makePeer "+0Ywt4hCtjrnp6BFD1yXDv+nkYyiTdni9TsqkZlwe30=" [ "10.0.1.48/32" ]) # ben
          (makePeer "dr0xJI+ATLPPNGJYxRduIBdKNwF1vPlY4MLxyjQ4tyY=" [ "10.0.1.49/32" ]) # ben
          (makePeer "omDZjdwQpIjisXPQoW86SDjjsLY9b/reINhgDiFtg0Y=" [ "10.0.1.50/32" ]) # hannah
          (makePeer "UJMUnlABs/tN2w1U/aXDNCH8ziFv+vJ8z9znwjSO33Y=" [ "10.0.1.51/32" ]) # hannah
          (makePeer "xiRBO03NsfXwWKVeHAKcM4ihAn1F8zw4Heocy7NPiWo=" [ "10.0.1.52/32" ]) # stephanie
          (makePeer "TC0Eg+JBERjTWPlfbOSoazt9fHD8eSTPFw8My7cdekg=" [ "10.0.1.53/32" ]) # stephanie
        ];
    };

    networks.wg0 = {
      matchConfig.Name = "wg0";
      address = [ "10.0.0.1/16" ];
      networkConfig = {
        IPMasquerade = "ipv4";
        IPv4Forwarding = "yes";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
