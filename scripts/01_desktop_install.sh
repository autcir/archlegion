#!/bin/bash

# =============================================================================
# PACUSER FASE 1: INSTALLAZIONE DESKTOP KDE PLASMA + DRIVER NVIDIA
# =============================================================================
# OBIETTIVO: Configurazione completa ambiente desktop per formattazione Arch Linux
#            - KDE Plasma ottimizzato e moderno
#            - Driver NVIDIA con supporto ibrido
#            - Localizzazione italiana completa
#            - Ottimizzazioni pacman e makepkg
# ESECUZIONE: ./01_desktop_install.sh
# PREREQUISITI: Sistema Arch Linux base installato
# =============================================================================


# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica prerequisiti
check_system_prerequisites || exit 1
check_not_root

log_info "🚀 AVVIO INSTALLAZIONE DESKTOP COMPLETA"

# --- FASE 1: PACMAN OPTIMIZATION ---
log_info "📦 Ottimizzazione pacman.conf..."
PAC_CONF="/etc/pacman.conf"
update_config "$PAC_CONF" "Color" "Color"
update_config "$PAC_CONF" "VerbosePkgLists" "VerbosePkgLists"
update_config "$PAC_CONF" "ParallelDownloads" "ParallelDownloads = 10"
if ! grep -q "ILoveCandy" "$PAC_CONF"; then
    sudo sed -i '/Color/a ILoveCandy' "$PAC_CONF"
fi

# Multilib
sudo sed -i '/^#\[multilib\]/,/Include/ s/^#//' "$PAC_CONF"

# --- FASE 2: MIRRORS & SYSTEM UPDATE ---
log_info "🌍 Ottimizzazione mirrorlist..."
pacuser_install "reflector"
sudo reflector --country Italy,Germany,France --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syu --noconfirm

# --- FASE 3: KERNEL & DRIVERS ---
GPU=$(detect_gpu)
log_info "🎮 GPU Rilevata: $GPU"

if [[ "$GPU" == "NVIDIA_PASCAL" ]]; then
    log_warning "Configurazione speciale per Pascal (GTX 1060)..."
    # Kernel LTS obbligatorio per compatibilità driver 550xx
    pacuser_install "linux-lts"
    pacuser_install "linux-lts-headers"
    
    # Cleanup driver ufficiali per evitare conflitti
    sudo pacman -Rdd --noconfirm nvidia nvidia-dkms nvidia-utils lib32-nvidia-utils 2>/dev/null || true
    
    # Installazione driver AUR 550xx
    for p in nvidia-550xx-dkms nvidia-550xx-utils nvidia-550xx-settings lib32-nvidia-550xx-utils; do
        pacuser_install "$p"
    done
else
    log_info "Installazione driver NVIDIA moderni..."
    pacuser_install "nvidia-dkms"
    pacuser_install "nvidia-utils"
    pacuser_install "lib32-nvidia-utils"
fi

# Driver comuni e display server
log_info "🖥️ Installazione Display Server e Driver base..."
pacuser_install "xorg-server"
pacuser_install "mesa"
pacuser_install "vulkan-intel"
pacuser_install "intel-media-driver"

# --- FASE 4: GRAPHICS & MULTIMEDIA ---
log_info "🎨 Installazione librerie grafiche e multimediali..."
PKGS_GFX=(
    "vulkan-icd-loader" "lib32-vulkan-icd-loader" "lib32-vulkan-driver" 
    "lib32-libgl" "lib32-libva" "lib32-libvdpau" "vulkan-tools"
    "ttf-liberation" "wqy-zenhei" "zenity"
    "gst-plugins-base-libs" "gst-plugins-good" "gst-plugins-bad" "gst-plugins-ugly"
    "libva-nvidia-driver" "libva-utils" "vdpauinfo"
)
for p in "${PKGS_GFX[@]}"; do pacuser_install "$p"; done

# --- FASE 5: AUDIO PIPEWIRE ---
log_info "🔊 Configurazione Audio PipeWire..."
sudo pacman -Rdd --noconfirm pulseaudio jack2 2>/dev/null || true
PKGS_AUDIO=("pipewire" "pipewire-pulse" "pipewire-alsa" "pipewire-jack" "wireplumber" "lib32-pipewire")
for p in "${PKGS_AUDIO[@]}"; do pacuser_install "$p"; done

# --- FASE 6: KDE PLASMA & APPS ---
log_info "🖥️ Installazione KDE Plasma..."
PKGS_KDE=("plasma-meta" "sddm" "sddm-kcm" "qt6-wayland" "dolphin" "konsole" "kate" "ark" "spectacle")
for p in "${PKGS_KDE[@]}"; do pacuser_install "$p"; done

# --- FASE 7: NETWORK & HARDWARE ---
log_info "🌐 Configurazione Network & Hardware..."
pacuser_install "networkmanager"
pacuser_install "libimobiledevice"
enable_service "NetworkManager.service"
enable_service "sddm.service" false

# SDDM Wayland Fix
log_info "⚙️ Configurazione SDDM/Wayland..."
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/10-wayland.conf > /dev/null <<EOF
[General]
DisplayServer=wayland
[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen
EOF

# --- FASE 8: GRUB TUNING ---
log_info "⚙️ Configurazione GRUB..."
GRUB_DEFAULT="/etc/default/grub"
if [[ "$GPU" == "NVIDIA_PASCAL" ]]; then
    update_config "$GRUB_DEFAULT" "GRUB_CMDLINE_LINUX_DEFAULT" 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia_drm.modeset=1 nvidia_drm.fbdev=1 usbcore.autosuspend=-1"'
else
    update_config "$GRUB_DEFAULT" "GRUB_CMDLINE_LINUX_DEFAULT" 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia_drm.modeset=1"'
fi
sudo grub-mkconfig -o /boot/grub/grub.cfg

log_success "🎉 FASE 1 COMPLETATA: Desktop & Driver installati!"
