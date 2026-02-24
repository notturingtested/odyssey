# Windows AI Server Setup - Design

## Purpose

Turn a Windows gaming PC with an NVIDIA GPU into a dedicated AI inference server accessible over Tailscale. No dev environment needed — just Ollama + Open WebUI served over the network.

## Architecture

Two-phase setup: PowerShell on Windows, then NixOS config inside WSL.

```
Windows (Host)
├── Tailscale (Windows service, always-on networking)
├── WSL2 + NixOS (default distro)
│   ├── Ollama (CUDA-accelerated, models on /mnt/c/ai-models)
│   ├── Open WebUI (container on port 3000)
│   └── Tailscale (WSL-side, systemd)
├── C:\ai-models (shared model storage)
└── C:\ai-images (shared image storage)
```

## File Structure

```
init/
├── windows.ps1         # Phase 1: Windows-side setup
├── nixos-setup.sh      # Phase 2: WSL/NixOS-side setup

nixos/
├── flake.nix           # Flake entry point
└── configuration.nix   # Full NixOS system config
```

## Phase 1: `init/windows.ps1`

PowerShell script run as Administrator on Windows:

1. Enable WSL2 + Virtual Machine Platform
2. Download and import NixOS-WSL distro, set as default
3. Install Tailscale via `winget`
4. Create `C:\ai-models` and `C:\ai-images`
5. Copy `nixos/` config into WSL at `/etc/nixos/`
6. Create Windows Scheduled Task to auto-start WSL on login
7. Kick off Phase 2 inside WSL
8. Echo next steps (reboot if needed, run Phase 2 manually if reboot was required)

Handles reboot detection — if WSL wasn't previously enabled, prompts for reboot and prints instructions to re-run.

## Phase 2: `init/nixos-setup.sh`

Bash script run inside WSL/NixOS:

1. Apply the NixOS flake: `sudo nixos-rebuild switch --flake /etc/nixos#wsl`
2. Verify GPU passthrough: `nvidia-smi`
3. Verify `/mnt/c/ai-models` and `/mnt/c/ai-images` are accessible
4. Enable and start systemd services (ollama, tailscaled)
5. Run `tailscale up` for interactive auth
6. Verify ollama is responding (`curl localhost:11434`)
7. Echo next steps (pull models, access Open WebUI URL, Tailscale device name)

## NixOS Flake Configuration

### `nixos/flake.nix`

Inputs:
- `nixpkgs` (unstable — latest ollama and CUDA support)
- `nixos-wsl` (NixOS-WSL module)

Output: NixOS system config named `wsl`.

### `nixos/configuration.nix`

Declares:
- **WSL integration** — enable WSL module, set default user
- **NVIDIA/CUDA** — CUDA toolkit for WSL GPU passthrough (WSL uses Windows host driver)
- **Ollama** — `services.ollama.enable`, CUDA acceleration, model dir at `/mnt/c/ai-models`
- **Open WebUI** — OCI container (podman), port 3000, connected to Ollama backend
- **Tailscale** — `services.tailscale.enable`, systemd auto-start
- **Systemd** — enabled in WSL, all services start on boot
- **Base packages** — curl, git, htop, nvtop (GPU monitoring)

## Auto-Start Chain

```
PC boots → Windows login → Scheduled Task runs `wsl -d NixOS` →
systemd starts → ollama + open-webui + tailscaled auto-start →
accessible from any Tailscale device
```

## Access Pattern

From any device on your Tailnet:
- **Open WebUI**: `http://<windows-tailscale-ip>:3000`
- **Ollama API**: `http://<windows-tailscale-ip>:11434`

## Each Script Echoes Next Steps

Both scripts print a summary of what was done and explicit next steps:
- `windows.ps1` prints: reboot instructions (if needed), how to re-run, how to start Phase 2
- `nixos-setup.sh` prints: Tailscale device name, Open WebUI URL, how to pull first model (`ollama pull`), how to verify from another device
