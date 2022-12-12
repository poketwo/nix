{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
}
