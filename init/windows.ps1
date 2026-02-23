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

# ── Banner ────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "   ________  ________  ________  ________  ________  ________      _______   ________  ________  ________  ________  ________  ________  ________ " -ForegroundColor Magenta
    Write-Host "  /        \/        \/        \/        \/        \/    /   \    /       \\/        \/        \/        \/        \/        \/        \/        \" -ForegroundColor Magenta
    Write-Host " /        _/         /         /         /        _/         /   /        //         /         /         /         /        _/         /         /" -ForegroundColor Magenta
    Write-Host "/-        /         /         /         //       //         /   /         /       __/        _/        _/         //       //         /        _/ " -ForegroundColor Magenta
    Write-Host "\_______//\__/__/__/\________/\________/ \______/ \___/____/    \________/\______/  \________/\____/___/\___/____/ \______/ \________/\____/___/  " -ForegroundColor Magenta
    Write-Host ""
}

# ── Main ─────────────────────────────────────────────────
function Main {
    Write-Banner
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
