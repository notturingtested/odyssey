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
