#Requires -RunAsAdministrator
###################################################################
# Name          windows.ps1
# Description   Sets up WSL2 + NixOS for AI inference on Windows
###################################################################

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "   OK: $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "   WARN: $msg" -ForegroundColor Yellow }

# ── Check / Enable WSL ──────────────────────────────────────────
function Install-WSL {
    Write-Step "Checking WSL installation..."

    try {
        wsl --status | Out-Null
        Write-Ok "WSL is installed"
    }
    catch {
        Write-Step "Enabling WSL2..."
        wsl --install --no-distribution
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Yellow
        Write-Host " REBOOT REQUIRED - Please reboot and re-run this script." -ForegroundColor Yellow
        Write-Host "===============================================================" -ForegroundColor Yellow
        exit 0
    }
}

# ── Install NixOS (Official Method) ─────────────────────────────
function Install-NixOS {

    Write-Step "Checking for existing NixOS distro..."

    $distros = wsl --list --quiet 2>$null
    if ($distros -match "^NixOS$") {
        Write-Ok "NixOS distro already exists"
        return
    }

    Write-Step "Installing NixOS via official WSL channel..."
    wsl --install -d NixOS

    Write-Ok "NixOS installed"
}

# ── Install Tailscale ───────────────────────────────────────────
function Install-Tailscale {

    Write-Step "Checking Tailscale installation..."

    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($ts) {
        Write-Ok "Tailscale already installed"
        return
    }

    Write-Step "Installing Tailscale via winget..."
    winget install --id Tailscale.Tailscale `
                   --accept-source-agreements `
                   --accept-package-agreements

    Write-Ok "Tailscale installed"
}

# ── Create Windows Directories ──────────────────────────────────
function New-AIDirs {

    Write-Step "Creating Windows AI directories..."

    New-Item -ItemType Directory -Force -Path "C:\ai-models" | Out-Null
    New-Item -ItemType Directory -Force -Path "C:\ai-images" | Out-Null

    Write-Ok "Created C:\ai-models"
    Write-Ok "Created C:\ai-images"
}

# ── Copy NixOS Configuration ────────────────────────────────────
function Copy-NixConfig {

    Write-Step "Copying NixOS configuration into WSL..."

    wsl -d NixOS -- bash -c "sudo mkdir -p /etc/nixos"

    $sourcePath = "/mnt/c/Users/$env:USERNAME/.odyssey/nixos"
    wsl -d NixOS -- bash -c "if [ -d '$sourcePath' ]; then sudo cp -r $sourcePath/* /etc/nixos/; fi"

    Write-Ok "Configuration copy step completed"
}

# ── Auto-Start WSL on Login ─────────────────────────────────────
function Set-WSLAutoStart {

    Write-Step "Configuring WSL auto-start..."

    $taskName = "Start-WSL-NixOS"
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Ok "Scheduled task already exists"
        return
    }

    $action   = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d NixOS -- true"
    $trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Start WSL NixOS on login for AI services"

    Write-Ok "WSL will auto-start on login"
}

# ── Main ────────────────────────────────────────────────────────
function Main {

    Write-Host ""
    Write-Host "===== Odyssey: Windows AI Server Setup =====" -ForegroundColor Magenta
    Write-Host ""

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
    Write-Host "  1. Launch NixOS once to initialize user account" -ForegroundColor White
    Write-Host "  2. Then run Phase 2 inside WSL" -ForegroundColor White
    Write-Host ""
}

Main
