let
  users = {
    oliver = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0idNvgGiucWgup/mP78zyC23uFjYq0evcWdjGQUaBH";
  };
  hosts = {
    articuno = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVOQ2837abtVB5VFebugFpPZrlRgnaa6oZ/CyoKWF5A";
    moltres = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH8Nhbguio4LnvLqlun91+pKBZZOXFn8HPOB1oxhbXqy";
    zapdos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEudPs8SqsTGL2HQM5lp7YFPPQ/YVfe0/4TuVLJ6Xtu";
  };
  allKeys = [ users.oliver hosts.articuno hosts.moltres hosts.zapdos ];
in
{
  "k3s-server-token.age".publicKeys = allKeys;
}
