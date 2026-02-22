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
          (makePeer "y/aU1KWZMUwCvCtQmdUeqDmS33yAXfFFv9qxajWnFT0=" [ "10.0.1.42/32" ])
          (makePeer "vp7UHe5TVEbbwvi9u6Ln+vUxkW1fQbmdMMyJ6E5ZAVg=" [ "10.0.1.43/32" ])
          (makePeer "xygFtdHsdBCTVLyh06uRqenkVqbJVkqJE//ljfx1PnI=" [ "10.0.1.44/32" ])
          (makePeer "CamMaplXLdZxqTm/Lq0qlsW2y7NL55NanqM1tc3PPA0=" [ "10.0.1.45/32" ])
          (makePeer "e0tchdbGS0S2qxjWgU4OPmwq573JAv7W9MCxctk/gxA=" [ "10.0.1.46/32" ])
          (makePeer "Q9JvARijVIKzG0NiHFqHz5PwlcwEeizhfMcuRVrIc20=" [ "10.0.1.47/32" ])
          (makePeer "LXann763GnXEZjrSAns1NMoyRROr1k52aAuPb5vwHkE=" [ "10.0.1.48/32" ])
          (makePeer "TVq0w4M0TtNlqq3tfoNzubzt3ymlWb8aBhK/ih4GvhA=" [ "10.0.1.49/32" ])
          (makePeer "v2rA+541a42q7ecJZ2NdZAwUkIgP6YKwsAG5rfLzLho=" [ "10.0.1.50/32" ])
          (makePeer "h7WEGIeC05f0HkPbbPhE3BAINySJbwKQczlJ2XopO3g=" [ "10.0.1.51/32" ])
          (makePeer "cMpafXKbCjTcOQ9b+q4QrnjEmg3aIT+4kpCwg99Kb3U=" [ "10.0.1.52/32" ])
          (makePeer "SW5l+Hl8r8KP8StK/CBQ2E3uXxqLrWKX3GeVYoQ0JBo=" [ "10.0.1.53/32" ])
          (makePeer "OU7HBnl5jvQ8FA+mX4nQCoZiCanVGHm5nNhA1uh/tD8=" [ "10.0.1.54/32" ])
          (makePeer "p8wp4xMcqJ5iPWSwKasv/s1A8rVar2lWsYzP/iFhHD0=" [ "10.0.1.55/32" ])
          (makePeer "K/vHJP3kmgVg7kywbj+v6d6cJ8QAVZJwps6pLTyisjs=" [ "10.0.1.56/32" ])
          (makePeer "OSeEc/AwmtBVI5TJa7lzqnFXynCtgPrGc2g01Cyoky4=" [ "10.0.1.57/32" ])
          (makePeer "Nkbgo9ednnPNhnyDoaQMe7CR+52IEEJ1GlHZvF9Pjg4=" [ "10.0.1.58/32" ])
          (makePeer "tkhvuiojbRdRgXA85HW3zJDobQxADZ4C8uWfnlWhCwA=" [ "10.0.1.59/32" ])
          (makePeer "8CzVF+HPjtFibgklnlUFlW9Y60NaUg/IVgD7bd+t8FM=" [ "10.0.1.60/32" ])
          (makePeer "fHHSEnzsr4IS4f7gSghJMlCJ56dzPS2+LrdRy5kQHnQ=" [ "10.0.1.61/32" ])
          (makePeer "hA5vX9wBLuJtgjSUaDMFgXfqZg9qaDT37rFutZYUJnk=" [ "10.0.1.62/32" ])
          (makePeer "xFcvtXHOF0vX3DQ048VbnYg515M/YFmYiniJlv3ICRs=" [ "10.0.1.63/32" ])
          (makePeer "AhT/5RYMSFvr9uWsiSH6nCECijPEm3hdtRvL+omBBAo=" [ "10.0.1.64/32" ])
          (makePeer "kj87HL0JCDBX37ewbNUDzJPtuZyRGdmklxo/XEtMOmo=" [ "10.0.1.65/32" ])
          (makePeer "Z8Xpx88cjcvX+3S+olm5e1jfgC2x6qyj4b222Jem4Qs=" [ "10.0.1.66/32" ])
          (makePeer "pCnaScCIH3eHaP2XdCBVq9+6HzHCNJiMslQ5eS6nsCg=" [ "10.0.1.67/32" ])
          (makePeer "xrEclsVpQ135nKlB0p6UkH6n6c8E4QfNvWoqd3YMQRU=" [ "10.0.1.68/32" ])
          (makePeer "zSKygsfmqv5dO73mh3xSION2jsW/Wb2wi0BuWUlWTGk=" [ "10.0.1.69/32" ])
          (makePeer "NDuCVWf06icCW799inItHnf/EtMXhgfd9gLfDfnfQHQ=" [ "10.0.1.70/32" ])
          (makePeer "vbOVjmyfuzOnvYWm//3AQG4wwL1xwPIsnXVUjJbIOXE=" [ "10.0.1.71/32" ])
          (makePeer "D/z/CnC7AhVkikTlKGvbJyVEaNNv1idWNGaeLSwlzwY=" [ "10.0.1.72/32" ])
          (makePeer "2Ndvt6OspD9rJS5kTM72LUBxOB6bAZbbjj1oh3xYIx4=" [ "10.0.1.73/32" ])
          (makePeer "F6yAR7tvMaI/r7FUr043bebqg36iUOblCjOKG0D89kA=" [ "10.0.1.74/32" ])
          (makePeer "pgibS1jg6AvDQY23Rn54zcDiRnZcLyuVrukfTaieGGo=" [ "10.0.1.75/32" ])
          (makePeer "M+SsrAGZEzfauiJKDuvaKAp92sq+dHnDBj0fFHgiPng=" [ "10.0.1.76/32" ])
          (makePeer "E6FpOvSERkxSODBwX+GpyPUwVljPT+achMig8oegKTE=" [ "10.0.1.77/32" ])
          (makePeer "H7iEojuaFSINs+xWz8P0ODyq5qaqDuC8I9Uho0R98gA=" [ "10.0.1.78/32" ])
          (makePeer "3dT7eOJdZ7j7dBFomZIXb48odx4f7f0XDFuIo3FGNH4=" [ "10.0.1.79/32" ])
          (makePeer "WV/WgWf0JyjdfGrjL4KHD9c6F7/1p7WLCXbO+C4OXxA=" [ "10.0.1.80/32" ])
          (makePeer "gn32YcLRU4iSYCRilbTkaowviq0f9ebYPVIDAJ6TNCM=" [ "10.0.1.81/32" ])
          (makePeer "BWjdAqF9UMJfEVpXzwKya6kFz29HZbjCV+Jhh5rYlAk=" [ "10.0.1.82/32" ])
          (makePeer "QZ2JND++gzt8RhS5d5P1UlN1XTNjhN4pYsvOOI4s4RE=" [ "10.0.1.83/32" ])
          (makePeer "mN3teOOtyNYehx13Kk24kLAPcGS5hDzhqD62UzpkVlI=" [ "10.0.1.84/32" ])
          (makePeer "iaop3TeIKdG/8RbfALtXE7xct8esMhl0XEFKy+WdMgQ=" [ "10.0.1.85/32" ])
          (makePeer "RZeSBdg4EKNpfx/DZjP+Z28wlc1odBjJKbU+DMRaHFg=" [ "10.0.1.86/32" ])
          (makePeer "AXb++uynXLZsJIrbPuIinsb5EFaxHSdh0+opHi2TQw4=" [ "10.0.1.87/32" ])
          (makePeer "ydHoiQfvob6f0aOAfSGHXgCHuurluudTRPtQaLhB/zo=" [ "10.0.1.88/32" ])
          (makePeer "F8QlPTdnBIQ3c7afSHNC22AYOtNebLmXpwqTHgy0t2E=" [ "10.0.1.89/32" ])
          (makePeer "iTNIp5SRNFnl3lrQgVNPEjTNYXvyF0X00MGHgmvaxw8=" [ "10.0.1.90/32" ])
          (makePeer "KJ5nE039Q6yptLkJNWaUrFXhiiS7VU7rMDanPGV8rTI=" [ "10.0.1.91/32" ])
          (makePeer "2Zvf4V1pWgdpVcBr0sfsS5K/cEtGEVWAW3QWRHULFRg=" [ "10.0.1.92/32" ])
          (makePeer "qAjwfOMx65l67RXUfZ/HyA0tpZJInLQCk5hFkcQAcVk=" [ "10.0.1.93/32" ])
          (makePeer "UJ+PWI3w9Ca9Udfvke/+4k6PA5BccvNG+ETlqlB+7xo=" [ "10.0.1.94/32" ])
          (makePeer "B8QIyqKPGAGMCDpEipN28lKZeM/qKBpaCzipO8q3ag4=" [ "10.0.1.95/32" ])
          (makePeer "3PL/HhSfGMyWTuy4yhvqtuhW9A50g6/vi3zxMkqNwHc=" [ "10.0.1.96/32" ])
          (makePeer "cUtIqs8md1mXY8u0atGmQRUPZY9Qcl6Hc0ssqzjHy3U=" [ "10.0.1.97/32" ])
          (makePeer "JP3bg8eo5ehlhrenaQ2QUzpvDeNUVZc3kyCUeRCe3XY=" [ "10.0.1.98/32" ])
          (makePeer "KhGLi6tzzH3PsXtYyMCdjN9QOTMWl+0P2rGPUw+zMCQ=" [ "10.0.1.99/32" ])
          (makePeer "qvLCiI1eOU5j7VYUV+ouYzwyMvnAfyvhCHD1XtnGLDc=" [ "10.0.1.100/32" ])
          (makePeer "wobBolDuxyyz2d++vnmUDJD7TXWuOA/GG/SS4ua0eVI=" [ "10.0.1.101/32" ])
          (makePeer "ctOYaqTL/amCEig3VWWwTN4T+od0jNLzfJyEEtLD8i8=" [ "10.0.1.102/32" ])
          (makePeer "k1wYzBsfEgn9nV8SDX+ixFqBN/mPuO7tOPHqW1z8EEg=" [ "10.0.1.103/32" ])
          (makePeer "BJu1STaBQTGx/KGaYYdPIY7E1cXd95ScuTM39D60/Fc=" [ "10.0.1.104/32" ])
          (makePeer "19U6gVA4Hd9wXYp0v0va6MNbIIEZb4/9eaDID4G8Pn8=" [ "10.0.1.105/32" ])
          (makePeer "1SBASOhX06idqvjdPH9n3VmeYszH9GZFLa0IqfsC2Vw=" [ "10.0.1.106/32" ])
          (makePeer "XMwlBvalVGmtju/RI5JQ9ukBxJHnbBK4ZSkLapGnYA8=" [ "10.0.1.107/32" ])
          (makePeer "C0i/TtKZyTwN5vdKH6qE6kfS4nCN4mPFH3B/dgtrRXw=" [ "10.0.1.108/32" ])
          (makePeer "MvvEXr8MY75pnFNllRwq5CyJqGFYJfgY3awz6I5rD2s=" [ "10.0.1.109/32" ])
          (makePeer "WHAIDYRI7Vlwuq40M/JpJLJF4mAhEJDqj/lfDu1+MGo=" [ "10.0.1.110/32" ])
          (makePeer "L5dwF5PJdADZAZfxz61ZzsIASfoEI9FzJy9ID5rmk1k=" [ "10.0.1.111/32" ])
          (makePeer "uzUretA3bEb4ub6w6woJVM0m0XBUwNCU3UAe7/ijZ3Y=" [ "10.0.1.112/32" ])
          (makePeer "fVihXcbujTOi4cWXUXq5PLSgbV2L/ClH95jFePFYxEI=" [ "10.0.1.113/32" ])
          (makePeer "R3W/DuzGmumBUewi3PYHNWoreLI0ZyWKMa6yJ3mLtwY=" [ "10.0.1.114/32" ])
          (makePeer "90aPXIh840Po8NRt/nDw2VNs+zu2xEyt+aN6SDdiigY=" [ "10.0.1.115/32" ])
          (makePeer "S53bMe7VwMhH63PX0o3sXIYxUwJK9qdNtmtqft/0eTA=" [ "10.0.1.116/32" ])
          (makePeer "WMpSI/LaHTJ/ySYiBXL9BwmPBANIroUJsVBTUrr/kmU=" [ "10.0.1.117/32" ])
          (makePeer "1+34r1giWtgEzbMTkDH6yVdc9nrSMX0lXYD1FpAfPi8=" [ "10.0.1.118/32" ])
          (makePeer "6deUwlB0Ljm7pPD7Ir3KfIzz80bXFUWFhSeIeyxkah0=" [ "10.0.1.119/32" ])
          (makePeer "kOseWNTvl4LKCwpPDaILpsw4DnK6SSyYOvFmgEWzFlY=" [ "10.0.1.120/32" ])
          (makePeer "5XMXRDhHpHyXG7po2HHhs4UiMRoTE8T0WJtW8u3VM3Q=" [ "10.0.1.121/32" ])
          (makePeer "rAc1K/3H/LJuGF8CCL6txCwQH91lbhH9jlY/+PKK0iw=" [ "10.0.1.122/32" ])
          (makePeer "B1MDo+kpYAQ9GRa7yR49BfRX0Qco6f2Xdj9aSrA872c=" [ "10.0.1.123/32" ])
          (makePeer "sXnheZby5dmJUssNJFhMVvOxVm/GNZ6dfnezRAkXwRE=" [ "10.0.1.124/32" ])
          (makePeer "Q44X+k3ztsG3F28eTF0H14IcITLovMKtPpj9ksiV+2E=" [ "10.0.1.125/32" ])
          (makePeer "5PaF1OSDt3xm7k/iDDgSCXWlUDXMnhqqpuMbLTzWqmY=" [ "10.0.1.126/32" ])
          (makePeer "SsJ/nu5Gudov5johp4vB+e8spc5i4qPiYlK6KYZ4dUc=" [ "10.0.1.127/32" ])
          (makePeer "eMDrSjX5ZmUkq3G3tPl34A03gi4A6DU0Ke+a0kaXkRM=" [ "10.0.1.128/32" ])
          (makePeer "cUpujURMiiliAqNc1bJxsopZlSEiOIHYzWIEHjS7Wzs=" [ "10.0.1.129/32" ])
          (makePeer "ui30+QuAK41c7k5bmWMAzen74Akfju7atKCAqHsHM1U=" [ "10.0.1.130/32" ])
          (makePeer "Oq46B0bWP4Mr+Dt8mWMgskl/tqa7137InYHhDYP8QzY=" [ "10.0.1.131/32" ])
          (makePeer "3cpCynq54+JqJEQI/8H/PNWnFpcNtBsPzohMMcQOQHA=" [ "10.0.1.132/32" ])
          (makePeer "HFUSakBfI3SC8C4IxXCJodf5IaBQA9gkV/DXK9Hpd2Y=" [ "10.0.1.133/32" ])
          (makePeer "VwRxsfD5oef+5/xxlS9n6wRHhEf0oUYGeD2I9us+KD8=" [ "10.0.1.134/32" ])
          (makePeer "G2wgavHt7QDt4NlkjrjKR4cCqMuGrktATI4FzfHohSA=" [ "10.0.1.135/32" ])
          (makePeer "eQL3bL+wrKSXksXa8vBxujTCxuCv8HYJphdd2lrlY0o=" [ "10.0.1.136/32" ])
          (makePeer "yJgwdjyqmlSXj7kmxADB1WZpuNzxxlOYPFDG4FukNno=" [ "10.0.1.137/32" ])
          (makePeer "yU3J3tY3RFWZTjR+hcBR3YAo+qqXa2yITe03g5NH+WE=" [ "10.0.1.138/32" ])
          (makePeer "eLAEmrK8woO8bXTtv+3Xz+i8tFy9zI+bE8RXthR5r0Q=" [ "10.0.1.139/32" ])
          (makePeer "CnJ/HSL49GUt4B8f/b4Fg7ymfOgPHLWsisxlhGKyylM=" [ "10.0.1.140/32" ])
          (makePeer "eaCv/6oaQxNNHQ4UrzU3pfiIr7nFqsdaTfJ65qGCVCo=" [ "10.0.1.141/32" ])
          (makePeer "HBBNAPPGhwbQ70mJw4LdeXhT0+205nY9yYdWt6J1Zns=" [ "10.0.1.142/32" ])
          (makePeer "ZFammlC6UoEVjO6lho5Q4BnciQX5DVnBD/T6SRaV/S8=" [ "10.0.1.143/32" ])
          (makePeer "7YAKfXAyWBOgllWr7XAfoUbjuvfLDiksuzsj9nTvByg=" [ "10.0.1.144/32" ])
          (makePeer "MzGP+0fxff0YZ1zay95y0nr619bIIS1iRf0uxUqxxQA=" [ "10.0.1.145/32" ])
          (makePeer "AXgR1IWSZYaQHvacKQWlbmSHgK3C0K7s+Wq+y7UzzDc=" [ "10.0.1.146/32" ])
          (makePeer "QkgfJZSw0WQ4HIhFQYhxLOV0s9Pvgici1UdMWagMjBI=" [ "10.0.1.147/32" ])
          (makePeer "LdO3756xCnxTRj6WRcO+IF1pupgoHecqSkN1cMW34zk=" [ "10.0.1.148/32" ])
          (makePeer "QjmHhfxdlhBEVb42zcEm12+I9wAsTcvhg3nQXdZ9B3I=" [ "10.0.1.149/32" ])
          (makePeer "gxyOAJrxOmvR7FhETAC+HrQc4LlRvLvT3Bhp+DsTBhE=" [ "10.0.1.150/32" ])
          (makePeer "8RHoYFQDCOYd+JBDpjM0BXRY/LYb2AYjAwg3i2pOSnk=" [ "10.0.1.151/32" ])
          (makePeer "5P9JxXVBZGxQVo8JSUWaN9hQZUVhqG0M2ArCNn1NZQU=" [ "10.0.1.152/32" ])
          (makePeer "DqNtAQJCt/753BSpR/CvtSE8FohgTPKVIpy97e7qtwo=" [ "10.0.1.153/32" ])
          (makePeer "3JLct0SWf1OjSFmjgR/Hsrk0TESrGkvrFw4C6ElMrCk=" [ "10.0.1.154/32" ])
          (makePeer "bcLA6ewcPrB9Bef6KsDpSf1CTdGiUKHeg9Ng5qzz8Ak=" [ "10.0.1.155/32" ])
          (makePeer "wnwa6PjDaxRbtOmjonsJzrmf3oNd9yBiJDra9F61IQw=" [ "10.0.1.156/32" ])
          (makePeer "JsoZ94jqFG0AcXYDyleVJM5tDSuBqg08Wxp6VUqfCG4=" [ "10.0.1.157/32" ])
          (makePeer "Osn9hQKjI9Za6mQmWvkrKoKJf4M8oAXbhclHSI70r28=" [ "10.0.1.158/32" ])
          (makePeer "4f7PiMi7hO8cEOkn6B7dZ0UcFcm/HigrEzGzhvZ4ZwE=" [ "10.0.1.159/32" ])
          (makePeer "6TkEkzuPa7iKz/0TZ8QhbtyLoUrqao7jESCU+W9T2jw=" [ "10.0.1.160/32" ])
          (makePeer "sSImL6sTew0ocBBnyF1xB5IBOGQ0CfAPypXRUuE8qVU=" [ "10.0.1.161/32" ])
          (makePeer "V+zpfabR8aYTEO85QiNQeO9oE3FZ+O2FseDJDDj9XWM=" [ "10.0.1.162/32" ])
          (makePeer "57FrosRjeAYawX8+Gux/P50RK9TfAQEgS/AmjC3q3hI=" [ "10.0.1.163/32" ])
          (makePeer "WU2tZyuMbiFhDLq2qGV587IYpfu9SdfES1IUBcdZnFE=" [ "10.0.1.164/32" ])
          (makePeer "QvhlsIy/PxUfNRSpLu9d0o4sHYex0xfUPzT1Hw5AhF8=" [ "10.0.1.165/32" ])
          (makePeer "k3mryQ0oQ9E0PLGKAVrbytwjtFEbtD5DYYSVZ0mysiU=" [ "10.0.1.166/32" ])
          (makePeer "Dle++0fqDK67M0ch2CSkeqrjiFl+RtfL6QoZjDK/gkg=" [ "10.0.1.167/32" ])
          (makePeer "Flo9/+A2T2p2tu7vHsHUDyeDGXvX3PKJ3BgvCaWuVE0=" [ "10.0.1.168/32" ])
          (makePeer "20xEjDyUFeZxt1KwI+rFzB5GWDpt+16aFIpIGLJkozI=" [ "10.0.1.169/32" ])
          (makePeer "c60DxMzhFcNd1eO+SC4tYkR5gxSmw8Uxe1UXroFgS0o=" [ "10.0.1.170/32" ])
          (makePeer "FxGFs8pdMefV9L+IZH44MxcOCkNQaDZdFrpbDhyYmXk=" [ "10.0.1.171/32" ])
          (makePeer "WNaLzNncjXfyLGk8XUSnHS+MJwAREryyjKJrgvVHM3Y=" [ "10.0.1.172/32" ])
          (makePeer "3sL5jF9E0OjbK2bAuNCTYvJ7S1LaMtkUUIjUH/QesGk=" [ "10.0.1.173/32" ])
          (makePeer "lhr47kaaJOy0Xftm3iyi22sDg3G9HwECYxiy8X7Btws=" [ "10.0.1.174/32" ])
          (makePeer "Pgz0I5q74p+ABKGQbyhdtsB7wd/K2cY4x4RDuusTwlY=" [ "10.0.1.175/32" ])
          (makePeer "uahojVtciVfJ7LR1pNh0bcQNRYr8ikcFGQ160u2TOTQ=" [ "10.0.1.176/32" ])
          (makePeer "QEugdjuU2ZgbY89eoSAaAlL4nqlZkVEqxdNSvSb6hjo=" [ "10.0.1.177/32" ])
          (makePeer "EZYWyBRep9lFGJpbRBawIA1GnooX5hU4St4KvVbiq3E=" [ "10.0.1.178/32" ])
          (makePeer "DBmuEAH9H4HtMmx+wtXrZovkmB2Lxz3dA9GBvZS4nWg=" [ "10.0.1.179/32" ])
          (makePeer "Ha99Kgkvnj5/lMHyzOMelb08rh4j51j+7UaNImF5HUE=" [ "10.0.1.180/32" ])
          (makePeer "sptCHgIln2Hxum2Z5EmwOr2zYWPyv5tusiNQAh2U/A4=" [ "10.0.1.181/32" ])
          (makePeer "MHtsNVWOr8MifmRwpx4/4cWLzRu2wmzL6uLgvDVqxRc=" [ "10.0.1.182/32" ])
          (makePeer "+9fhH6NVvEnWNt44DECph2DVmV953LY6MAFaMyzd504=" [ "10.0.1.183/32" ])
          (makePeer "eAhlJdq5UgJnb1mznyvjid6TfFKHv3jvwI/emzYgmwk=" [ "10.0.1.184/32" ])
          (makePeer "SLcVh6ob3WJEjjzj5NT8ua3dnIYN512sobwlZ2BFKzA=" [ "10.0.1.185/32" ])
          (makePeer "wSNcANg0ztGDD7F3mec9NVhHTnAKgXw92nI20ARRYUM=" [ "10.0.1.186/32" ])
          (makePeer "JU01OMzFXPinnVC+8vOoiKL3S54mElQNkeROLMgCUXM=" [ "10.0.1.187/32" ])
          (makePeer "S/a0tWGjMGz+n20uXWXkRSDmywMOdX2UOI9vKJMACWU=" [ "10.0.1.188/32" ])
          (makePeer "usEYUBCBDtDEqyMa1wSikq3SiPl7735medTy6TDlbjY=" [ "10.0.1.189/32" ])
          (makePeer "2fprGtdpDSK+O2mFz+611Ja1ZQ80AACozhFRvcfwogY=" [ "10.0.1.190/32" ])
          (makePeer "tekOL7kdko2Xfu+T4/xUrWgYipkYp5jaL1DSMea6yVw=" [ "10.0.1.191/32" ])
          (makePeer "wmlpFBduXHdbAUOuqOEuu9KEv+zv1BpVaxaJ+9qBpl4=" [ "10.0.1.192/32" ])
          (makePeer "1zHIcPuCrJ/Fdr6Tl6px4r9ZRgiGnNHn1P3pa4jW20c=" [ "10.0.1.193/32" ])
          (makePeer "dPVIf4zklryUsoc9IUk5zzxltXLykSyjtnK0bYrksno=" [ "10.0.1.194/32" ])
          (makePeer "qy3JcgCKCVofeFQrquusip4/53OQSf+L02lh3g3aWms=" [ "10.0.1.195/32" ])
          (makePeer "HlRH+U5qiU/Jg1zzr5hjO7TzYr+MsEJI+zSbX6N0FnA=" [ "10.0.1.196/32" ])
          (makePeer "ZwHdeK5e3WxfT0kKoB3BYqHWPLc/DjnovmlAnnA6Hh8=" [ "10.0.1.197/32" ])
          (makePeer "q3enoqZuuZJNFWZN0dxVNGO9Q9qRbYK8w8L8AOrGZzk=" [ "10.0.1.198/32" ])
          (makePeer "wzTybhN/awwboCszzSFkUY8eoCpBqk4pw4F5f/yEywI=" [ "10.0.1.199/32" ])
          (makePeer "ipmBJBGMZ+14O8myztSvzKNOjOQ9WiCYBSnCo1/cxkc=" [ "10.0.1.200/32" ])
          (makePeer "FV9XUE7gxqaRCfFFezaJBFnO3Ts4RBZokkz5KmVpGzY=" [ "10.0.1.201/32" ])
          (makePeer "QWeaIY/71UunFoUJBZVhXei7u9txY6Zhesi34OQz5nY=" [ "10.0.1.202/32" ])
          (makePeer "SdFD0eneBRrd6S6DpXERFmkxOwRIZdxy879XpbT5UnI=" [ "10.0.1.203/32" ])
          (makePeer "cv+uTmmBciVrMaHIQ7phnLU4xpJL4k8oP73+zFiAXAw=" [ "10.0.1.204/32" ])
          (makePeer "B2Nvr5JkP5THPUL2bU+xPFj7KmxYypaFgeg24+Tp+AU=" [ "10.0.1.205/32" ])
          (makePeer "SRUvMm0omzHy17mt161oAcRhGv+b+yPTkf7ydI7DDUQ=" [ "10.0.1.206/32" ])
          (makePeer "GHXPw0AQS+8+k7SpBazt1MIsLg9Y7pWkcp4L6p4SIBQ=" [ "10.0.1.207/32" ])
          (makePeer "zEZxW86xX439u8AUCyzyroeBclqrem3cjMWwAAruKDU=" [ "10.0.1.208/32" ])
          (makePeer "HSNffbpzj//69J77HVnn0KWiNlUKwfA4XIMqk/vGNGg=" [ "10.0.1.209/32" ])
          (makePeer "QSu/YxdjBSJJvoU+q6UfsI/ZdaYOUz1/0t46V5WyH0E=" [ "10.0.1.210/32" ])
          (makePeer "dJ4cVCtspvee9oSUOOWJ9Z9+wpKuai9YwNXUmtKKOwA=" [ "10.0.1.211/32" ])
          (makePeer "YRlakHDhS3Tx4CbMj6nSvDkrVTqA0LacgtoOuwYeK14=" [ "10.0.1.212/32" ])
          (makePeer "v+aD5ctIcz1kY0MJkgIXyxiBtcn90jlQ1+q6H8Qj/WI=" [ "10.0.1.213/32" ])
          (makePeer "3vfmUMshR55A640GnGI4JThepdqUvCtKPyOz03zGEW4=" [ "10.0.1.214/32" ])
          (makePeer "qAwFtl0RXJqssiuGXO4qjMeuy2YLffQ/wt+T2M6Nh2Q=" [ "10.0.1.215/32" ])
          (makePeer "x8TWrm0IqGuWgw8My4Wdtdy95roNhyal8OARifY2VVI=" [ "10.0.1.216/32" ])
          (makePeer "6cwbCRwRzc0qvjWBV9POUP4uW4V5yNPGtgsRcDuPb1M=" [ "10.0.1.217/32" ])
          (makePeer "1ievK4ARRGA2KMaWiixfTcV6fQ4eNmU9arnF48e9hz0=" [ "10.0.1.218/32" ])
          (makePeer "DHBAuc+4FjDVL86oJNZ6hWropbHJ+CJyar3kdv/WQ2I=" [ "10.0.1.219/32" ])
          (makePeer "AnxL7HXAbnbVrNFyZODgDd9p7ZnI+q8EAkcgGmtUa0g=" [ "10.0.1.220/32" ])
          (makePeer "N/fPXriJujjtWaA8GIEQWVilznJLUdwwPr3ugUr7lFo=" [ "10.0.1.221/32" ])
          (makePeer "cCRmq1zvv/hL4cR9Ztc0CpSWJrdCIlTKg8U/1i+qQjo=" [ "10.0.1.222/32" ])
          (makePeer "zzD/Qqz7gduYkP8BIoY0ATwQRXa6zLa+uAaysQ7wD0w=" [ "10.0.1.223/32" ])
          (makePeer "RrL5CdSVcYLkKxgVRwDFoELVps598NYSgkslA/gWSG0=" [ "10.0.1.224/32" ])
          (makePeer "SAtChsatHP8aeQRZnG7M9YriZWGw2dA9AgVoTg807mI=" [ "10.0.1.225/32" ])
          (makePeer "DoDDtdqZGyUlqPuonHkrLgw3OL35CHfk89lUZJtL7W8=" [ "10.0.1.226/32" ])
          (makePeer "/9bJZgdOg7f8myxecqIGJ4d2cfnwT/enR/0qPsjSqF8=" [ "10.0.1.227/32" ])
          (makePeer "8NUNq4c0BSqHziMBX9jdBScSCvvo6a8SgQlS93H1IRU=" [ "10.0.1.228/32" ])
          (makePeer "Nr1oetkmfp/YJ7zilNd7BhDLgN+Ug6u6pwnV/NXBgQk=" [ "10.0.1.229/32" ])
          (makePeer "dAxl2rsyPyvx89lfZS60LZ4V+gjTDdju6Lb1/kGBfGU=" [ "10.0.1.230/32" ])
          (makePeer "isZwkXcJxBtm8YZMvL6GMbW8g41A6/AwgijVIRq+Gi4=" [ "10.0.1.231/32" ])
          (makePeer "AG5cV0d1NqnVXmZ5xOfrqv/MdpTCvlt60IIjGtjlFR4=" [ "10.0.1.232/32" ])
          (makePeer "3+/wLZxgVCcYPZyemkod7fLjqgxk2xOrwsJMwtC2yS8=" [ "10.0.1.233/32" ])
          (makePeer "WrtUG373/G5b4hh/y2WUnAS2RCaQfs78fEDYOsVyWXY=" [ "10.0.1.234/32" ])
          (makePeer "bEuvr7Mt1/Hv1vZa2Ic40TCJwNhC01mmCf+uRN9/tgs=" [ "10.0.1.235/32" ])
          (makePeer "voU8yY4hxQVW1GBgGGFz5RYb/4UQfShYoPL7XKSi/3A=" [ "10.0.1.236/32" ])
          (makePeer "m7exSg98AdphYPji6xcVDBzkLRiKfwU2I/vGqXQWiks=" [ "10.0.1.237/32" ])
          (makePeer "iDvTfoBzIRUDXesi/OxkelthX6qxZ/5lFOwwJf37M3g=" [ "10.0.1.238/32" ])
          (makePeer "fbAZQYk1wbwfAcL3rUOjxymU7ICjFBjhu7xfz0CDk1M=" [ "10.0.1.239/32" ])
          (makePeer "+OBQJwRv4Jk8TRsexY1NkASyEcTKifTiOEbu1P70aFo=" [ "10.0.1.240/32" ])
          (makePeer "Eiwug8UGRGAMy3MHFC6rapN9YNZyVZpW+fdUEKyyilU=" [ "10.0.1.241/32" ])
          (makePeer "1HG4d7fF2RmCk1ZRSnFQhIwdCBT2ihR+crzDUH8gJC4=" [ "10.0.1.242/32" ])
          (makePeer "wrNUauGQuorh3+92EQ3odlr7LjfpP5iFDSeC3gh6dVU=" [ "10.0.1.243/32" ])
          (makePeer "xeYlZz2Wn5bCrNUUqtUIK5NLWzPlc/eJrXYSf44qElo=" [ "10.0.1.244/32" ])
          (makePeer "bzH/aA/iV1FLf6pHvdpbP++IKtll4ymrytdNS7PlyT4=" [ "10.0.1.245/32" ])
          (makePeer "foZrYmKZSZengdK15Ljl1zGfQBAVIb5j2bUJ7bL7tUo=" [ "10.0.1.246/32" ])
          (makePeer "QD+dcVC4KtEdxhudBhvLsZ+SpaXU+iYywMTDdeZrewU=" [ "10.0.1.247/32" ])
          (makePeer "1a670n0DzTuoHe9a+4rgp7eIfE6DKngKQjAaxHy53F0=" [ "10.0.1.248/32" ])
          (makePeer "XBqS7xWz49FchEs/nUElLGZWVSlEC3mGR990uvGWcTg=" [ "10.0.1.249/32" ])
          (makePeer "IDPZPI6LUr1H8xzSy5GxtqX+MxcGR0u3R3KBOxIUZkQ=" [ "10.0.1.250/32" ])
          (makePeer "zkTh9IvEPqTMjBOyNxAM1vZuoFAVjutmR4eHGfOSnjM=" [ "10.0.1.251/32" ])
          (makePeer "X8K2Efm7+UUXLDP2JHPAHsTg24TcoHPffhRvRC6Lg18=" [ "10.0.1.252/32" ])
          (makePeer "Z2w+51Dnpk1jcPmVYbHqx1P5TTL58ZLrarWy2O6x2UQ=" [ "10.0.1.253/32" ])
          (makePeer "8MWDVbqrpi6hgmr1gRGaF+/5J1/bg8U2qVBSLjS3V2U=" [ "10.0.1.254/32" ])
          (makePeer "HIAxG57MeZMOkPpPKI1kIojp68TcKXG2XuWYXD7UBkQ=" [ "10.0.1.255/32" ])
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
