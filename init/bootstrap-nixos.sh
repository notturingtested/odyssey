#!/usr/bin/env bash
###################################################################
# Name          bootstrap-nixos.sh
# Description   Bootstrap Odyssey on a fresh NixOS WSL instance
# Usage         nix-shell -p curl --run "bash <(curl -fsSL https://raw.githubusercontent.com/notturingtested/odyssey/main/init/bootstrap-nixos.sh)"
###################################################################

set -e

REPO_URL="https://github.com/notturingtested/odyssey.git"
REPO_DIR="$HOME/.odyssey"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${CYAN}>> $1${NC}"; }
ok()   { echo -e "   ${GREEN}OK: $1${NC}"; }
fail() { echo -e "   ${RED}FAIL: $1${NC}"; exit 1; }

# ── Clone repo ─────────────────────────────────────────
step "Cloning Odyssey repo..."
if [ -d "$REPO_DIR" ]; then
    ok "Repo already exists at $REPO_DIR — pulling latest"
    git -C "$REPO_DIR" pull
else
    nix-shell -p git --run "git clone $REPO_URL $REPO_DIR"
    ok "Cloned to $REPO_DIR"
fi

# ── Run setup ─────────────────────────────────────────
step "Running NixOS setup..."
exec bash "$REPO_DIR/init/nixos-setup.sh"
