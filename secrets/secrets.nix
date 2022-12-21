let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlViRB5HH1bTaS1S7TcqVBSuxKdrbdhL2CmhDqc/t6A";
  };

  hosts = {
    articuno = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVOQ2837abtVB5VFebugFpPZrlRgnaa6oZ/CyoKWF5A";
    moltres = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8Nhbguio4LnvLqlun91+pKBZZOXFn8HPOB1oxhbXqy";
    zapdos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEudPs8SqsTGL2HQM5lp7YFPPQ/YVfe0/4TuVLJ6Xtu";
    abra = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEht+0QZ6DDJfKEQtTO8JrAn3SI6AY9s/YLakfnIVGcP";
    blissey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfn0tyrAbzvkAMoPzIzbfAPvqkk7YOk7mloUSevb2xK";
    corsola = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHRDXyQ1YEzZRWjP7fnkgZYLPuYkkpxQ7QIkZ/qZIPmb";
    deino = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF4jL3YVR2qAhWTQ9RRu2w6NYlc0/RsiWJ9FRiuB0CiW";
    eevee = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINmpJE08R0PopFAMqZ3Lm7Qv6P3VERSz37rOWSgpaxEh";
  };

  admins = with users; [ oliver ];
  k3s-servers = with hosts; [ articuno moltres zapdos ];
  k3s-workers = with hosts; [ abra blissey corsola deino eevee ];
in
{
  "k3s-server-token.age".publicKeys = admins ++ k3s-servers;
  "k3s-agent-token.age".publicKeys = admins ++ k3s-servers ++ k3s-workers;
}
