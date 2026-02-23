#Requires -RunAsAdministrator
###################################################################
# Name          windows.ps1
# Description   Fully automated WSL2 + NixOS-WSL install + AI server setup
#               with progress, error checking, and fail-safe exit
###################################################################

$ErrorActionPreference = "Stop"

function Write-Step { param([string]$msg) Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "   OK: $msg" -ForegroundColor Green }
function Write-Warn { param([string]$msg) Write-Host "   WARN: $msg" -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

# - Invoke-Download: tries BITS, WebClient, Invoke-WebRequest -
# Runs with SilentlyContinue so the global Stop preference doesn't
# swallow inner catch blocks.
function Invoke-Download {
    param([string]$Url, [string]$Dest)
    $local:ErrorActionPreference = "SilentlyContinue"

    # Try BITS
    try {
        Start-BitsTransfer -Source $Url -Destination $Dest -DisplayName "Downloading NixOS-WSL" -ErrorAction Stop
        if ((Test-Path $Dest) -and (Get-Item $Dest).Length -gt 0) { return $true }
    } catch {
        Write-Warn "BITS failed: $_"
    }
    if (Test-Path $Dest) { Remove-Item $Dest -Force }

    # Try WebClient
    try {
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $Dest)
        if ((Test-Path $Dest) -and (Get-Item $Dest).Length -gt 0) { return $true }
    } catch {
        Write-Warn "WebClient failed: $_"
    }
    if (Test-Path $Dest) { Remove-Item $Dest -Force }

    # Try Invoke-WebRequest
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing -ErrorAction Stop
        if ((Test-Path $Dest) -and (Get-Item $Dest).Length -gt 0) { return $true }
    } catch {
        Write-Warn "Invoke-WebRequest failed: $_"
    }

    return $false
}

# - Check / Enable WSL -
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

# - Download & Install NixOS-WSL -
function Install-NixOS {

    Write-Step "Checking for existing NixOS distro..."

    $distros = (wsl --list --quiet 2>$null) -join " "
    $distros = $distros -replace "`0", "" -replace "`r", ""
    if ($distros -match "NixOS") {
        Write-Ok "NixOS distro already exists"
        return
    }

    Write-Step "Fetching latest release metadata from GitHub..."
    $apiUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    try { $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing } catch { Write-Err "Failed to fetch GitHub release metadata." }

    $asset = $release.assets | Where-Object { $_.name -like "*.wsl" } | Select-Object -First 1
    if (-not $asset) { Write-Err "Could not find a .wsl installer asset in release." }

    $wslFile      = Join-Path $env:TEMP $asset.name
    $expectedSize = $asset.size

    Write-Host "   Asset      : $($asset.name) ($expectedSize bytes)"
    Write-Host "   URL        : $($asset.browser_download_url)"
    Write-Host "   Destination: $wslFile"

    # Check valid cache
    if (Test-Path $wslFile) {
        $cachedSize = (Get-Item $wslFile).Length
        if ($cachedSize -eq $expectedSize) {
            Write-Ok "Using verified cached file ($cachedSize bytes)"
        } else {
            Write-Warn "Cached file is $cachedSize bytes, expected $expectedSize - deleting."
            Remove-Item $wslFile -Force
        }
    }

    # Download with retry
    if (-not (Test-Path $wslFile)) {
        $maxAttempts = 3
        $downloaded  = $false

        for ($i = 1; $i -le $maxAttempts; $i++) {
            Write-Step "Downloading (attempt $i of $maxAttempts)..."

            $ok = Invoke-Download -Url $asset.browser_download_url -Dest $wslFile

            if (-not $ok) {
                Write-Warn "All download methods failed on attempt $i."
                continue
            }

            $actualSize = (Get-Item $wslFile).Length
            Write-Host "   Got $actualSize bytes, expected $expectedSize bytes"

            if ($actualSize -eq $expectedSize) {
                Write-Ok "Download verified"
                $downloaded = $true
                break
            } else {
                Write-Warn "Size mismatch on attempt $i - retrying."
                Remove-Item $wslFile -Force
            }
        }

        if (-not $downloaded) {
            Write-Err "Download failed after $maxAttempts attempts."
        }
    }

    # Install the .wsl file
    Write-Step "Installing NixOS from .wsl file..."
    $result = wsl --install --from-file "$wslFile" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "wsl --install failed (exit $LASTEXITCODE): $result"
    }

    Write-Ok "NixOS installation command issued"
}

# - Wait until WSL Registers NixOS -
function Wait-ForNixOS {
    Write-Step "Waiting for NixOS to register with WSL..."
    $tries = 0
    do {
        Start-Sleep -Seconds 3
        $distros = ((wsl --list --quiet 2>$null) -join " ") -replace "`0", "" -replace "`r", ""
        $tries++
        if ($tries -gt 30) { Write-Err "NixOS did not register within 90s." }
    } until ($distros -match "NixOS")
    Write-Ok "NixOS is now registered in WSL"
}

# - Install Tailscale -
function Install-Tailscale {
    Write-Step "Checking Tailscale installation..."
    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($ts) { Write-Ok "Tailscale already installed"; return }

    Write-Step "Installing Tailscale via winget..."
    try {
        winget install --id Tailscale.Tailscale `
                       --accept-source-agreements `
                       --accept-package-agreements
    } catch { Write-Err "Failed to install Tailscale via winget." }

    Write-Ok "Tailscale installed"
}

# - Create Windows Directories -
function New-AIDirs {
    Write-Step "Creating Windows AI directories..."
    try {
        New-Item -ItemType Directory -Force -Path "C:\ai-models" | Out-Null
        New-Item -ItemType Directory -Force -Path "C:\ai-images" | Out-Null
    } catch { Write-Err "Failed to create AI directories." }
    Write-Ok "Directories created"
}

# - Copy NixOS Configuration -
function Copy-NixConfig {
    Write-Step "Copying NixOS config into WSL..."
    try {
        wsl -d NixOS -- bash -c "sudo mkdir -p /etc/nixos"
        $sourcePath = "/mnt/c/Users/$env:USERNAME/.odyssey/nixos"
        wsl -d NixOS -- bash -c "if [ -d '$sourcePath' ]; then sudo cp -r $sourcePath/* /etc/nixos/; fi"
    } catch { Write-Err "Failed to copy NixOS config." }
    Write-Ok "Configuration copied"
}

# - Auto-Start WSL on Login -
function Set-WSLAutoStart {
    Write-Step "Configuring WSL auto-start..."
    $taskName = "Start-WSL-NixOS"
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) { Write-Ok "Scheduled task exists"; return }

    try {
        $action   = New-ScheduledTaskAction -Execute "wsl.exe" -Argument "-d NixOS -- true"
        $trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Description "Start NixOS WSL on login"
    } catch { Write-Err "Failed to create auto-start task." }

    Write-Ok "Auto-start task created"
}

# - Main -
function Main {
    Write-Host ""
    Write-Host "===== Odyssey: Windows AI Server Setup =====" -ForegroundColor Magenta
    Write-Host ""

    Install-WSL
    Install-NixOS
    Wait-ForNixOS

    Install-Tailscale
    New-AIDirs
    Copy-NixConfig
    Set-WSLAutoStart

    Write-Host ""
    Write-Host "===== Setup Complete =====" -ForegroundColor Green
    Write-Host "Next Steps:"
    Write-Host "Copy bootstrap-setup.sh into nixos, chmod and run"
    Write-Host "Launching NixOS..." -ForegroundColor Cyan
    wsl -d NixOS
}

Main
