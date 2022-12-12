{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "$(head -c 8 /etc/machine-id)";
}
