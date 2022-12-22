#! /usr/bin/env nix-shell
#! nix-shell -i bash -p git

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root!"
  exit
fi

echo "Writing bootstrap configuration..."

cat <<EOF >bootstrap.nix
{ pkgs, ... }: {
  imports = [ ./configuration.nix ];
  environment.systemPackages = [ pkgs.tailscale ];
  services.tailscale.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
EOF

echo "Building bootstrap configuration..."

nixos-rebuild switch -I nixos-config=./bootstrap.nix

echo "Starting tailscale..."

tailscale up --ssh

read -p "Upload configs, then press enter to continue..."

echo "Downloading new configs..."

rm -rf *
git clone https://github.com/poketwo/nix.git .

echo "Building configs..."

nixos-rebuild switch
