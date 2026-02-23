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
    package = pkgs.ollama-cuda;
    # Acceleration options:
    # pkgs.ollama-cuda      NVIDIA GPU
    # pkgs.ollama-rocm      AMD GPU
    # pkgs.ollama-vulkan    Vulkan (experimental)
    # pkgs.ollama-cpu       CPU only
    # pkgs.ollama           Default (usually CPU)
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

  # ── Tailscale Serve (expose services over tailnet) ───
  # Started manually by setup script after tailscale auth
  systemd.services.tailscale-serve = {
    description = "Configure Tailscale Serve for AI services";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = lib.mkForce [];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "tailscale-serve-setup" ''
        while ! ${pkgs.tailscale}/bin/tailscale status > /dev/null 2>&1; do
          sleep 2
        done
        ${pkgs.tailscale}/bin/tailscale serve --bg --https=443 http://localhost:3000
        ${pkgs.tailscale}/bin/tailscale serve --bg --https=11434 http://localhost:11434
      '';
    };
  };

  # ── Base Packages ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
    nvtopPackages.nvidia
    jq
    cudaPackages.cudatoolkit
  ];

  # ── Networking ────────────────────────────────────────
  networking.hostName = "smooth-operator";
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 3000 11434 ];
  };

  system.stateVersion = "24.11";
}
