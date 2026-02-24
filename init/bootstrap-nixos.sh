#!/usr/bin/env bash
# bootstrap.sh — fetch Odyssey configs and kick off Phase 2

set -e

REPO="https://raw.githubusercontent.com/notturingtested/odyssey/main"

echo ">> Fetching NixOS configs..."
nix-shell -p curl --run "
  sudo curl -fsSL $REPO/nixos/flake.nix -o /etc/nixos/flake.nix
  sudo curl -fsSL $REPO/nixos/configuration.nix -o /etc/nixos/configuration.nix
  curl -fsSL $REPO/init/nixos-setup.sh -o /tmp/nixos-setup.sh
"

echo ">> Making setup script executable..."
chmod +x /tmp/nixos-setup.sh

echo ">> Running Phase 2 setup..."
exec /tmp/nixos-setup.sh
