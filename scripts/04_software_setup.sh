#!/bin/bash
# =============================================================================
# PACUSER FASE 4: DEVOPS, CLOUD & AI STACK
# =============================================================================
# OBIETTIVO: Installazione stack completo per sviluppo DevOps
#            - Git & Toolchain base
#            - Docker & NVIDIA Container Runtime
#            - Kubernetes tools (kubectl, helm, k9s)
#            - IDE (VSCode, Windsurf)
#            - Cloud CLI (Google Cloud)
#            - Hardware specific (Lenovo Legion)
# ESECUZIONE: ./04_software_setup.sh
# PREREQUISITI: Fase 3 completata
# VERSION: 2.0.0
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica prerequisiti
check_system_prerequisites || exit 1
check_not_root

log_info "🚀 AVVIO FASE 4: SOFTWARE STACK"

# --- FASE 1: GIT & TOOLCHAIN ---
log_info "📦 Configurazione Git e Toolchain base..."

PKGS_BASE=(
    "git"
    "github-cli"
    "base-devel"
    "curl"
    "wget"
    "jq"
    "yq"
    "ripgrep"
    "fd"
    "bat"
    "fzf"
    "htop"
    "btop"
    "tree"
    "unzip"
    "p7zip"
)

for p in "${PKGS_BASE[@]}"; do
    pacuser_install "$p"
done

# Git Config (da pacuser.conf o secrets)
GIT_NAME="${GIT_USER_NAME:-}"
GIT_EMAIL="${GIT_USER_EMAIL:-}"

if [[ -n "$GIT_NAME" ]]; then
    git config --global user.name "$GIT_NAME"
    log_success "Git user.name configurato: $GIT_NAME"
fi

if [[ -n "$GIT_EMAIL" ]]; then
    git config --global user.email "$GIT_EMAIL"
    log_success "Git user.email configurato: $GIT_EMAIL"
fi

# Configurazioni Git comuni
git config --global init.defaultBranch main
git config --global core.editor vim
git config --global pull.rebase false
git config --global push.autoSetupRemote true
git config --global color.ui auto

log_success "Git configurato"

# --- FASE 2: DOCKER & KUBERNETES ---
log_info "🐳 Configurazione Docker (NVIDIA & Smart Storage)..."

PKGS_CONTAINER=(
    "docker"
    "docker-compose"
    "docker-buildx"
)

for p in "${PKGS_CONTAINER[@]}"; do
    pacuser_install "$p"
done

# NVIDIA Container Toolkit (se GPU NVIDIA presente)
GPU_TYPE=$(detect_gpu)
DOCKER_NVIDIA="${PACUSER_DOCKER_NVIDIA:-1}"

if [[ "$GPU_TYPE" == NVIDIA_* && "$DOCKER_NVIDIA" == "1" ]]; then
    log_info "Installazione NVIDIA Container Toolkit..."
    pacuser_install "nvidia-container-toolkit"
fi

# Kubernetes Tools
log_info "☸️ Installazione Kubernetes tools..."

PKGS_K8S=(
    "kubectl"
    "kubectx"
    "helm"
    "k9s"
)

for p in "${PKGS_K8S[@]}"; do
    pacuser_install "$p"
done

# Smart Docker & Containerd Redirect (da config)
# Default su HDD se disponibile, altrimenti var/lib
if mountpoint -q /mnt/docker; then
    DOCKER_ROOT="/mnt/docker/docker-data"
    CONTAINERD_ROOT="/mnt/docker/containerd"
    log_success "Rilevato HDD Docker: configurazione su /mnt/docker"
else
    DOCKER_ROOT="${PACUSER_DOCKER_ROOT:-/var/lib/docker}"
    CONTAINERD_ROOT="/var/lib/containerd"
    log_info "Uso path standard: $DOCKER_ROOT"
fi

sudo mkdir -p "$DOCKER_ROOT" "$CONTAINERD_ROOT"

# Configurazione Containerd (per evitare uso root partition)
log_info "Configurazione containerd..."
sudo mkdir -p /etc/containerd
if [[ "$CONTAINERD_ROOT" != "/var/lib/containerd" ]]; then
    sudo tee /etc/containerd/config.toml >/dev/null <<EOF
version = 2
root = "$CONTAINERD_ROOT"
state = "/run/containerd"
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
      default_runtime_name = "nvidia"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
        runtime_type = "io.containerd.runc.v2"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
          BinaryName = "/usr/bin/nvidia-container-runtime"
          SystemdCgroup = true
EOF
    log_success "Containerd configurato su $CONTAINERD_ROOT"
fi

# Configurazione Docker daemon
log_info "Configurazione Docker daemon..."
sudo mkdir -p /etc/docker

# Costruisci config JSON
DOCKER_CONFIG='{
  "data-root": "'$DOCKER_ROOT'",
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "features": {
    "buildkit": true
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "exec-opts": ["native.cgroupdriver=systemd"]'

# Aggiungi NVIDIA runtime se disponibile
if [[ "$GPU_TYPE" == NVIDIA_* && "$DOCKER_NVIDIA" == "1" ]]; then
    DOCKER_CONFIG="$DOCKER_CONFIG"',
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }'
fi

DOCKER_CONFIG="$DOCKER_CONFIG"'
}'

echo "$DOCKER_CONFIG" | sudo tee /etc/docker/daemon.json >/dev/null

# Abilita e avvia servizi
enable_service "containerd.service"
enable_service "docker.service"

# Aggiungi utente al gruppo docker
CURRENT_USER="${PACUSER_USERNAME:-$USER}"
if ! groups "$CURRENT_USER" | grep -q docker; then
    sudo usermod -aG docker "$CURRENT_USER"
    log_warning "Utente $CURRENT_USER aggiunto al gruppo docker"
    log_warning "Effettua logout/login o esegui: newgrp docker"
fi

log_success "Docker configurato (data-root: $DOCKER_ROOT)"

# --- FASE 3: OPTIMIZE STORAGE (/OPT OFFLOAD) ---
log_info "💾 Ottimizzazione spazio storage (/opt offload)..."
OPT_OFFLOAD="/home/$USER/opt-offload"

if mountpoint -q /home; then
    # Se opt non è ancora un mountpoint
    if ! mountpoint -q /opt; then
        sudo mkdir -p "$OPT_OFFLOAD"

        # Se /opt ha contenuto, spostalo
        if [ "$(ls -A /opt 2>/dev/null)" ]; then
            log_info "Spostamento contenuto /opt -> $OPT_OFFLOAD..."
            sudo rsync -a /opt/ "$OPT_OFFLOAD/"
            sudo rm -rf /opt/*
        fi

        # Mount bind
        sudo mount --bind "$OPT_OFFLOAD" /opt
        log_success "/opt spostato su /home (risparmio spazio root)"
    fi
fi

# --- FASE 4: IDEs & DEV STACK ---
log_info "💻 Installazione IDE e Ambiente di Sviluppo..."

# IDE da installare (da config)
INSTALL_IDES="${PACUSER_INSTALL_IDES:-vscode windsurf}"

for ide in $INSTALL_IDES; do
    case "$ide" in
        vscode)
            pacuser_install "visual-studio-code-bin"
            ;;
        windsurf)
            pacuser_install "windsurf-bin"
            ;;
        antigravity)
            pacuser_install "antigravity-bin"
            ;;
        *)
            log_warning "IDE sconosciuto: $ide"
            ;;
    esac
done

# Node.js & Package Managers
log_info "📦 Installazione Node.js e package managers..."
pacuser_install "nodejs"
pacuser_install "npm"

# pnpm (package manager veloce)
if ! command_exists pnpm; then
    sudo npm install -g pnpm
    log_success "pnpm installato"
fi

# Python tools
log_info "🐍 Installazione Python tools..."
pacuser_install "python"
pacuser_install "python-pip"

# UV - Python package manager veloce (alternativa a pip)
if ! command_exists uv; then
    if pacuser_install "uv"; then
        log_success "UV installato"
    else
        # Fallback: installa via pip
        pip install --user uv 2>/dev/null || true
    fi
fi

# --- FASE 5: CLOUD CLI ---
log_info "☁️ Installazione Cloud CLI..."

# Google Cloud SDK
if pacuser_install "google-cloud-cli"; then
    # Plugin aggiuntivi
    pacuser_install "google-cloud-cli-gke-gcloud-auth-plugin" || true
    log_success "Google Cloud CLI installato"
fi

# Terraform (Infrastructure as Code)
pacuser_install "terraform" || true

# --- FASE 6: CONTAINER TOOLS ---
log_info "🛠️ Installazione Container Tools..."

# LazyDocker - TUI per Docker
pacuser_install "lazydocker" || true

# Dive - Analisi immagini Docker
pacuser_install "dive" || true

# --- FASE 7: HARDWARE SPECIFIC (LEGION) ---
LEGION_TOOLS="${PACUSER_LEGION_TOOLS:-1}"

if [[ "$LEGION_TOOLS" == "2" ]] || { [[ "$LEGION_TOOLS" == "1" ]] && is_lenovo_legion; }; then
    log_info "🛡️ Installazione Lenovo Legion Tools..."
    pacuser_install "lenovo-legion-toolkit-bin" || true
    log_success "Lenovo Legion Toolkit installato"
elif is_laptop; then
    log_info "💻 Laptop rilevato (non Legion), skip Legion tools"
fi

# --- FASE 8: ELECTRON GPU ACCELERATION ---
ELECTRON_GPU="${PACUSER_ELECTRON_GPU_ACCEL:-1}"

if [[ "$ELECTRON_GPU" == "1" && "$GPU_TYPE" == NVIDIA_* ]]; then
    log_info "⚡ Configurazione GPU acceleration per Electron..."

    # Configurazione flags per VSCode
    VSCODE_FLAGS="$HOME/.config/code-flags.conf"
    mkdir -p "$(dirname "$VSCODE_FLAGS")"

    cat > "$VSCODE_FLAGS" <<'EOF'
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization
EOF

    # Configurazione flags globali Electron
    ELECTRON_FLAGS="$HOME/.config/electron-flags.conf"
    cp "$VSCODE_FLAGS" "$ELECTRON_FLAGS"

    log_success "GPU acceleration configurata per Electron apps"
fi

# --- RIEPILOGO FINALE ---
echo ""
echo "==========================================="
log_success "🎉 FASE 4 COMPLETATA: SOFTWARE STACK"
echo "==========================================="
echo ""
log_info "Software installato:"
echo "  ✅ Git & Toolchain (ripgrep, fd, bat, fzf, etc.)"
echo "  ✅ Docker (data-root: $DOCKER_ROOT)"
[[ "$GPU_TYPE" == NVIDIA_* && "$DOCKER_NVIDIA" == "1" ]] && echo "  ✅ NVIDIA Container Runtime"
echo "  ✅ Kubernetes tools (kubectl, helm, k9s, kubectx)"
echo "  ✅ IDE: $INSTALL_IDES"
echo "  ✅ Node.js + pnpm"
echo "  ✅ Python + UV"
echo "  ✅ Google Cloud CLI"
echo "  ✅ LazyDocker, Dive"
[[ "$LEGION_TOOLS" != "0" ]] && is_lenovo_legion && echo "  ✅ Lenovo Legion Toolkit"
echo ""
log_info "Comandi utili:"
echo "  • docker run hello-world     # Test Docker"
echo "  • lazydocker                  # TUI Docker"
echo "  • k9s                         # TUI Kubernetes"
echo "  • gcloud init                 # Setup Google Cloud"
echo ""
log_warning "NOTA: Per usare Docker senza sudo, esegui: newgrp docker"
echo ""
echo "==========================================="
