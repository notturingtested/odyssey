# Windows AI Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Windows setup to the odyssey repo that installs WSL2 + NixOS, configures Ollama + Open WebUI with CUDA GPU passthrough, and auto-starts everything over Tailscale on boot.

**Architecture:** Two-phase setup — `init/windows.ps1` handles Windows-side prerequisites (WSL, Tailscale, dirs, scheduled task), then `init/nixos-setup.sh` configures the NixOS system inside WSL via a Nix flake that declares all services declaratively.

**Tech Stack:** PowerShell, Bash, Nix Flakes, NixOS-WSL, Ollama, Open WebUI (Podman container), Tailscale, NVIDIA CUDA (WSL passthrough)

---

### Task 1: Create NixOS Flake

**Files:**
- Create: `nixos/flake.nix`

**Step 1: Create the flake**

```nix
{
  description = "NixOS WSL - AI inference server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... }: {
    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.wsl
        ./configuration.nix
      ];
    };
  };
}
```

**Step 2: Commit**

```bash
git add nixos/flake.nix
git commit -m "feat: add NixOS flake for WSL AI server"
```

---

### Task 2: Create NixOS Configuration

**Files:**
- Create: `nixos/configuration.nix`

**Step 1: Create the configuration**

```nix
{ config, pkgs, lib, ... }:

{
  # ── WSL ────────────────────────────────────────────────
  wsl = {
    enable = true;
    defaultUser = "nixos";
    wslConf.automount.root = "/mnt";
    useWindowsDriver = true; # NVIDIA GPU passthrough
  };

  # ── Nix Settings ──────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;

  # ── NVIDIA / CUDA ────────────────────────────────────
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
  };
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
  ];

  # ── Ollama ────────────────────────────────────────────
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    port = 11434;
    home = "/mnt/c/ai-models";
  };

  # ── Open WebUI (OCI container) ────────────────────────
  virtualisation.podman.enable = true;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      ports = [ "0.0.0.0:3000:8080" ];
      environment = {
        OLLAMA_BASE_URL = "http://host.containers.internal:11434";
      };
      volumes = [
        "open-webui-data:/app/backend/data"
      ];
      autoStart = true;
    };
  };

  # ── Tailscale ─────────────────────────────────────────
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # ── Systemd ───────────────────────────────────────────
  # NixOS-WSL supports systemd natively
  # All services above are managed by systemd and auto-start on boot

  # ── Base Packages ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    nvtop
    jq
    cudaPackages.cudatoolkit
  ];

  # ── Networking ────────────────────────────────────────
  networking.hostName = "ai-server";
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 3000 11434 ];
  };

  system.stateVersion = "24.11";
}
```

**Step 2: Commit**

```bash
git add nixos/configuration.nix
git commit -m "feat: add NixOS config with ollama, open-webui, tailscale, CUDA"
```

---

### Task 3: Create Windows Setup Script (Phase 1)

**Files:**
- Create: `init/windows.ps1`

**Step 1: Create the PowerShell script**

```powershell
#Requires -RunAsAdministrator
###################################################################
# Name          windows.ps1
# Description   Sets up WSL2 + NixOS for AI inference on Windows
# Author        Braydn Tanner
###################################################################

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok { param([string]$msg) Write-Host "   OK: $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "   WARN: $msg" -ForegroundColor Yellow }

# ── Check WSL ────────────────────────────────────────────
function Install-WSL {
    Write-Step "Checking WSL installation..."

    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Step "Enabling WSL2..."
        wsl --install --no-distribution
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host "  REBOOT REQUIRED" -ForegroundColor Yellow
        Write-Host "  WSL2 has been enabled. Please reboot, then re-run:" -ForegroundColor Yellow
        Write-Host "  .\init\windows.ps1" -ForegroundColor White
        Write-Host "================================================================" -ForegroundColor Yellow
        exit 0
    }
    Write-Ok "WSL2 is installed"
}

# ── Install NixOS-WSL ────────────────────────────────────
function Install-NixOS {
    Write-Step "Checking for NixOS distro..."

    $distros = wsl --list --quiet 2>&1
    if ($distros -match "NixOS") {
        Write-Ok "NixOS distro already exists"
        return
    }

    Write-Step "Downloading NixOS-WSL..."
    $nixosUrl = "https://github.com/nix-community/NixOS-WSL/releases/latest/download/nixos-wsl.tar.gz"
    $nixosTar = "$env:TEMP\nixos-wsl.tar.gz"

    if (-not (Test-Path $nixosTar)) {
        Invoke-WebRequest -Uri $nixosUrl -OutFile $nixosTar -UseBasicParsing
    }

    Write-Step "Importing NixOS distro..."
    $nixosDir = "$env:LOCALAPPDATA\NixOS"
    New-Item -ItemType Directory -Force -Path $nixosDir | Out-Null
    wsl --import NixOS $nixosDir $nixosTar
    wsl --set-default NixOS

    Write-Ok "NixOS imported and set as default"
}

# ── Install Tailscale ────────────────────────────────────
function Install-Tailscale {
    Write-Step "Checking Tailscale..."

    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($ts) {
        Write-Ok "Tailscale already installed"
        return
    }

    Write-Step "Installing Tailscale via winget..."
    winget install --id Tailscale.Tailscale --accept-source-agreements --accept-package-agreements
    Write-Ok "Tailscale installed"
}

# ── Create Windows Dirs ──────────────────────────────────
function New-AIDirs {
    Write-Step "Creating Windows AI directories..."

    New-Item -ItemType Directory -Force -Path "C:\ai-models" | Out-Null
    New-Item -ItemType Directory -Force -Path "C:\ai-images" | Out-Null

    Write-Ok "Created C:\ai-models"
    Write-Ok "Created C:\ai-images"
}

# ── Copy NixOS Config ────────────────────────────────────
function Copy-NixConfig {
    Write-Step "Copying NixOS configuration into WSL..."

    $scriptDir = Split-Path -Parent $PSScriptRoot
    $nixosSource = Join-Path $scriptDir "nixos"

    wsl -d NixOS -- bash -c "sudo mkdir -p /etc/nixos"
    wsl -d NixOS -- bash -c "sudo cp -r /mnt/c/Users/$env:USERNAME/.odyssey/nixos/* /etc/nixos/"

    Write-Ok "NixOS config copied to /etc/nixos/"
}

# ── Auto-Start WSL on Login ──────────────────────────────
function Set-WSLAutoStart {
    Write-Step "Creating scheduled task to auto-start WSL on login..."

    $taskName = "Start-WSL-NixOS"
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Ok "Scheduled task already exists"
        return
    }

    $action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d NixOS -- true"
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Start WSL NixOS on login for AI services"

    Write-Ok "WSL will auto-start on login"
}

# ── Main ─────────────────────────────────────────────────
function Main {
    Write-Host "===== Odyssey: Windows AI Server Setup =====" -ForegroundColor Magenta

    Install-WSL
    Install-NixOS
    Install-Tailscale
    New-AIDirs
    Copy-NixConfig
    Set-WSLAutoStart

    Write-Host ""
    Write-Host "===== Phase 1 Complete =====" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Open Tailscale on Windows and sign in" -ForegroundColor White
    Write-Host "  2. Run Phase 2 (NixOS setup) with:" -ForegroundColor White
    Write-Host "     wsl -d NixOS -- bash /mnt/c/Users/$env:USERNAME/.odyssey/init/nixos-setup.sh" -ForegroundColor Cyan
    Write-Host "  3. Phase 2 will configure Ollama, Open WebUI, GPU, and Tailscale inside NixOS" -ForegroundColor White
    Write-Host ""
}

Main
```

**Step 2: Commit**

```bash
git add init/windows.ps1
git commit -m "feat: add windows.ps1 - Phase 1 WSL/NixOS setup"
```

---

### Task 4: Create NixOS Setup Script (Phase 2)

**Files:**
- Create: `init/nixos-setup.sh`

**Step 1: Create the setup script**

```bash
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

# ── Print Summary ────────────────────────────────────────
print_summary() {
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "<tailscale-ip>")
    HOSTNAME=$(hostname)

    echo ""
    echo -e "${GREEN}===== Phase 2 Complete =====${NC}"
    echo ""
    echo -e "${YELLOW}SERVICES RUNNING:${NC}"
    echo "  Ollama:     http://localhost:11434"
    echo "  Open WebUI: http://localhost:3000"
    echo "  Tailscale:  $TAILSCALE_IP ($HOSTNAME)"
    echo ""
    echo -e "${YELLOW}ACCESS FROM OTHER DEVICES (via Tailscale):${NC}"
    echo -e "  Open WebUI: ${CYAN}http://$TAILSCALE_IP:3000${NC}"
    echo -e "  Ollama API: ${CYAN}http://$TAILSCALE_IP:11434${NC}"
    echo ""
    echo -e "${YELLOW}NEXT STEPS:${NC}"
    echo -e "  1. Pull your first model:"
    echo -e "     ${CYAN}ollama pull llama3.2${NC}"
    echo -e "  2. Open WebUI in a browser from any Tailscale device:"
    echo -e "     ${CYAN}http://$TAILSCALE_IP:3000${NC}"
    echo -e "  3. Create your Open WebUI admin account on first visit"
    echo -e "  4. To monitor GPU usage:"
    echo -e "     ${CYAN}nvtop${NC}"
    echo -e "  5. Models are stored at: ${CYAN}C:\\ai-models${NC} (Windows) / ${CYAN}/mnt/c/ai-models${NC} (WSL)"
    echo ""
    echo -e "${YELLOW}AUTO-START:${NC}"
    echo "  All services start automatically when WSL boots."
    echo "  WSL starts automatically on Windows login (via Scheduled Task)."
    echo "  If the PC is on and logged in, everything is accessible over Tailscale."
    echo ""
}

# ── Main ─────────────────────────────────────────────────
main() {
    echo -e "${CYAN}===== Odyssey: NixOS AI Server Setup (Phase 2) =====${NC}"

    apply_config
    verify_gpu
    verify_dirs
    setup_tailscale
    verify_ollama
    verify_webui
    print_summary
}

main "$@"
```

**Step 2: Commit**

```bash
git add init/nixos-setup.sh
git commit -m "feat: add nixos-setup.sh - Phase 2 NixOS/AI config"
```

---

### Task 5: Final Commit and Verify

**Step 1: Verify all files exist**

```bash
ls -la nixos/flake.nix nixos/configuration.nix init/windows.ps1 init/nixos-setup.sh
```

**Step 2: Final commit if any changes remain**

```bash
git status
# Stage any remaining changes and commit
```
