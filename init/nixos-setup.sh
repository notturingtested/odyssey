#!/usr/bin/env bash
###################################################################
# Name          nixos-setup.sh
# Description   Phase 2: Configure NixOS inside WSL for AI inference
# Author        Braydn Tanner
###################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

step() { echo -e "\n${CYAN}>> $1${NC}"; }
ok() { echo -e "   ${GREEN}OK: $1${NC}"; }
warn() { echo -e "   ${YELLOW}WARN: $1${NC}"; }
fail() { echo -e "   ${RED}FAIL: $1${NC}"; exit 1; }

# ── Apply NixOS Config ───────────────────────────────────
apply_config() {
    step "Applying NixOS configuration via flake..."
    sudo nixos-rebuild switch --flake /etc/nixos#wsl
    ok "NixOS configuration applied"
}

# ── Verify GPU ───────────────────────────────────────────
verify_gpu() {
    step "Verifying NVIDIA GPU passthrough..."
    if nvidia-smi > /dev/null 2>&1; then
        nvidia-smi
        ok "GPU passthrough working"
    else
        fail "nvidia-smi failed. Check that:
   - NVIDIA drivers are installed on Windows
   - WSL2 is using the latest kernel (wsl --update)
   - You have rebooted after driver installation"
    fi
}

# ── Verify Windows Dirs ──────────────────────────────────
verify_dirs() {
    step "Verifying Windows-backed directories..."

    if [ -d "/mnt/c/ai-models" ]; then
        ok "/mnt/c/ai-models is accessible"
    else
        warn "/mnt/c/ai-models not found — create it on Windows: mkdir C:\\ai-models"
    fi

    if [ -d "/mnt/c/ai-images" ]; then
        ok "/mnt/c/ai-images is accessible"
    else
        warn "/mnt/c/ai-images not found — create it on Windows: mkdir C:\\ai-images"
    fi
}

# ── Tailscale Auth ───────────────────────────────────────
setup_tailscale() {
    step "Setting up Tailscale..."
    sudo systemctl enable --now tailscaled
    ok "Tailscale daemon running"

    step "Authenticating Tailscale (browser will open)..."
    sudo tailscale up
    ok "Tailscale connected"

    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    ok "Tailscale IP: $TAILSCALE_IP"
}

# ── Verify Ollama ────────────────────────────────────────
verify_ollama() {
    step "Verifying Ollama..."
    sudo systemctl enable --now ollama

    sleep 3

    if curl -sf http://localhost:11434 > /dev/null 2>&1; then
        ok "Ollama is running on port 11434"
    else
        warn "Ollama not responding yet — may need a moment to start"
    fi
}

# ── Verify Open WebUI ────────────────────────────────────
verify_webui() {
    step "Verifying Open WebUI container..."

    sleep 5

    if curl -sf http://localhost:3000 > /dev/null 2>&1; then
        ok "Open WebUI is running on port 3000"
    else
        warn "Open WebUI not responding yet — container may still be pulling/starting"
    fi
}

# ── Verify Tailscale Serve ────────────────────────────────
verify_tailscale_serve() {
    step "Configuring Tailscale Serve..."
    sudo systemctl start tailscale-serve 2>/dev/null || true

    if tailscale serve status 2>/dev/null | grep -q "443"; then
        ok "Tailscale Serve is running (HTTPS on ports 443, 11434)"
    else
        warn "Tailscale Serve may not be active yet — will start on next boot"
    fi
}

# ── Print Summary ────────────────────────────────────────
print_summary() {
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "<tailscale-ip>")
    TS_HOSTNAME=$(tailscale status --self=true --peers=false 2>/dev/null | awk '{print $2}' || echo "<hostname>")
    HOSTNAME=$(hostname)

    echo ""
    echo -e "${GREEN}===== Phase 2 Complete =====${NC}"
    echo ""
    echo -e "${YELLOW}SERVICES RUNNING:${NC}"
    echo "  Ollama:          http://localhost:11434"
    echo "  Open WebUI:      http://localhost:3000"
    echo "  Tailscale:       $TAILSCALE_IP ($HOSTNAME)"
    echo ""
    echo -e "${YELLOW}TAILSCALE SERVE (HTTPS via tailnet):${NC}"
    echo -e "  Open WebUI: ${CYAN}https://${TS_HOSTNAME}${NC}"
    echo -e "  Ollama API: ${CYAN}https://${TS_HOSTNAME}:11434${NC}"
    echo ""
    echo -e "${YELLOW}ACCESS FROM OTHER DEVICES (via Tailscale IP):${NC}"
    echo -e "  Open WebUI: ${CYAN}http://$TAILSCALE_IP:3000${NC}"
    echo -e "  Ollama API: ${CYAN}http://$TAILSCALE_IP:11434${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo -e "  1. Pull your first model:"
    echo -e "     ${CYAN}ollama pull llama3.2${NC}"
    echo -e "  2. Open WebUI in a browser from any Tailscale device:"
    echo -e "     ${CYAN}https://${TS_HOSTNAME}${NC}"
    echo -e "  3. Create your Open WebUI admin account on first visit"
    echo -e "  4. To monitor GPU usage:"
    echo -e "     ${CYAN}nvtop${NC}"
    echo -e "  5. Models are stored at: ${CYAN}C:\\ai-models${NC} (Windows) / ${CYAN}/mnt/c/ai-models${NC} (WSL)"
    echo ""
    echo -e "${YELLOW}AUTO-START:${NC}"
    echo "  All services (including Tailscale Serve) start automatically when WSL boots."
    echo "  WSL starts automatically on Windows login (via Scheduled Task)."
    echo "  If the PC is on and logged in, everything is accessible over Tailscale."
    echo ""
}

# ── Banner ────────────────────────────────────────────────
print_banner() {
    echo ""
    echo -e "${MAGENTA}   ________  ________  ________  ________  ________  ________      _______   ________  ________  ________  ________  ________  ________  ________ ${NC}"
    echo -e "${MAGENTA}  /        \\/        \\/        \\/        \\/        \\/    /   \\    /       \\\\/        \\/        \\/        \\/        \\/        \\/        \\/        \\\\${NC}"
    echo -e "${MAGENTA} /        _/         /         /         /        _/         /   /        //         /         /         /         /        _/         /         /${NC}"
    echo -e "${MAGENTA}/-        /         /         /         //       //         /   /         /       __/        _/        _/         //       //         /        _/ ${NC}"
    echo -e "${MAGENTA}\\_______//\\__/__/__/\\________/\\________/ \\______/ \\___/____/    \\________/\\______/  \\________/\\____/___/\\___/____/ \\______/ \\________/\\____/___/  ${NC}"
    echo ""
}

# ── Main ─────────────────────────────────────────────────
main() {
    print_banner
    echo -e "${CYAN}===== Odyssey: NixOS AI Server Setup (Phase 2) =====${NC}"

    apply_config
    verify_gpu
    verify_dirs
    setup_tailscale
    verify_ollama
    verify_webui
    verify_tailscale_serve
    print_summary
}

main "$@"
