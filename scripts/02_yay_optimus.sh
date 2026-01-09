#!/bin/bash

# =============================================================================
# PACUSER FASE 2: INSTALLAZIONE YAY + OPTIMUS MANAGER
# =============================================================================
# OBIETTIVO: Configurazione gestione grafica ibrida
#            - Installazione AUR helper (yay)
#            - Optimus Manager per switching NVIDIA/Intel (Hybrid mode)
# ESECUZIONE: ./02_yay_optimus.sh
# PREREQUISITI: Fase 1 completata
# VERSION: 2.0.0
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica prerequisiti
check_system_prerequisites || exit 1
check_not_root

log_info "🚀 AVVIO FASE 2: YAY & OPTIMUS MANAGER"

# --- FASE 1: INSTALLAZIONE YAY ---
log_info "📦 Verifica/Installazione AUR helper (yay)..."

if command_exists yay; then
    log_success "yay già installato"
else
    install_yay
    log_success "yay installato"
fi

# Aggiorna database AUR
log_info "Aggiornamento database AUR..."
yay -Sy --noconfirm 2>/dev/null || true

# --- FASE 2: RILEVAMENTO GPU ---
GPU_TYPE=$(detect_gpu)
log_info "🎮 GPU Rilevata: $GPU_TYPE"

# Verifica se è necessario Optimus Manager
case "$GPU_TYPE" in
    NVIDIA_MODERN|NVIDIA_PASCAL|NVIDIA_MAXWELL)
        NEEDS_OPTIMUS=true
        ;;
    *)
        NEEDS_OPTIMUS=false
        log_info "GPU non NVIDIA o non ibrida, Optimus Manager non necessario"
        ;;
esac

# --- FASE 3: INSTALLAZIONE OPTIMUS MANAGER ---
if [[ "$NEEDS_OPTIMUS" == "true" ]]; then
    log_info "⚙️ Installazione Optimus Manager..."

    # Installa optimus-manager
    pacuser_install "optimus-manager"

    # Installa GUI (opzionale ma utile)
    pacuser_install "optimus-manager-qt"

    # --- FASE 4: CONFIGURAZIONE ---
    log_info "⚙️ Configurazione Optimus Manager..."

    CONF="/etc/optimus-manager/optimus-manager.conf"
    MODE="${PACUSER_OPTIMUS_MODE:-hybrid}"

    sudo mkdir -p "$(dirname "$CONF")"

    # Configurazione basata sul tipo di GPU
    case "$GPU_TYPE" in
        NVIDIA_PASCAL|NVIDIA_MAXWELL)
            # GPU legacy: configurazione più conservativa
            log_info "Configurazione per GPU legacy ($GPU_TYPE)..."
            sudo tee "$CONF" >/dev/null <<EOF
# =============================================================================
# PACUSER Optimus Manager Configuration
# GPU Type: $GPU_TYPE (Legacy)
# =============================================================================

[optimus]
# Modalità di switching
switching=none
pci_power_control=no
pci_remove=no
pci_reset=no

# Modalità di avvio
startup_mode=$MODE
startup_auto_battery_mode=$MODE
startup_auto_extpower_mode=$MODE

[intel]
driver=modesetting
modeset=yes
accel=

[nvidia]
modeset=yes
PAT=yes
DPI=96
options=overclocking
# Dynamic Power Management disabilitato per GPU legacy
dynamic_power_management=no

[amd]
driver=modesetting
EOF
            ;;
        NVIDIA_MODERN)
            # GPU moderne: può usare DPM
            log_info "Configurazione per GPU moderna ($GPU_TYPE)..."
            sudo tee "$CONF" >/dev/null <<EOF
# =============================================================================
# PACUSER Optimus Manager Configuration
# GPU Type: $GPU_TYPE (Modern)
# =============================================================================

[optimus]
# Modalità di switching
switching=none
pci_power_control=no
pci_remove=no
pci_reset=no

# Modalità di avvio
startup_mode=$MODE
startup_auto_battery_mode=hybrid
startup_auto_extpower_mode=$MODE

[intel]
driver=modesetting
modeset=yes
accel=

[nvidia]
modeset=yes
PAT=yes
DPI=96
options=overclocking
# Dynamic Power Management per risparmio energetico
dynamic_power_management=fine

[amd]
driver=modesetting
EOF
            ;;
    esac

    log_success "Configurazione Optimus Manager: mode=$MODE"

    # --- FASE 5: ABILITAZIONE SERVIZIO ---
    ENABLE_OPTIMUS="${PACUSER_ENABLE_OPTIMUS_MANAGER:-0}"

    if [[ "$ENABLE_OPTIMUS" == "1" ]]; then
        log_info "Abilitazione servizio Optimus Manager..."
        enable_service "optimus-manager.service"
        log_success "Optimus Manager abilitato e avviato"
    else
        log_warning "Optimus Manager installato ma NON abilitato"
        log_info "Per abilitarlo manualmente:"
        echo "  sudo systemctl enable --now optimus-manager.service"
        echo ""
        log_info "Oppure imposta PACUSER_ENABLE_OPTIMUS_MANAGER=1 in pacuser.conf"
    fi

    # --- FASE 6: CONFIGURAZIONE SDDM (se presente) ---
    if systemctl is-enabled sddm.service &>/dev/null; then
        log_info "Configurazione SDDM per Optimus Manager..."

        # Crea script di pre-start per SDDM
        SDDM_SCRIPT="/etc/sddm/scripts/pacuser-optimus.sh"
        sudo mkdir -p "$(dirname "$SDDM_SCRIPT")"

        sudo tee "$SDDM_SCRIPT" >/dev/null <<'EOF'
#!/bin/bash
# PACUSER: Script pre-SDDM per Optimus Manager
# Assicura che la GPU corretta sia attiva prima del login

# Verifica che optimus-manager sia attivo
if systemctl is-active optimus-manager.service &>/dev/null; then
    # Forza refresh della configurazione
    optimus-manager --print-startup &>/dev/null || true
fi
EOF

        sudo chmod +x "$SDDM_SCRIPT"
        log_success "Script SDDM configurato"
    fi

else
    log_info "Optimus Manager non necessario per questa configurazione GPU"
fi

# --- FASE 7: INSTALLAZIONE TOOL AGGIUNTIVI ---
log_info "🔧 Installazione tool grafici aggiuntivi..."

# envycontrol - alternativa più semplice a optimus-manager
if [[ "$NEEDS_OPTIMUS" == "true" ]]; then
    if pacuser_install "envycontrol"; then
        log_success "envycontrol installato (alternativa a optimus-manager)"
    fi
fi

# nvidia-settings per configurazione GPU
if [[ "$GPU_TYPE" == NVIDIA_* ]]; then
    pacuser_install "nvidia-settings"
    log_success "nvidia-settings installato"
fi

# --- FASE 8: VERIFICA INSTALLAZIONE ---
log_info "🔍 Verifica installazione..."

ERRORS=0

# Verifica yay
if ! command_exists yay; then
    log_error "yay non installato correttamente"
    ((ERRORS++))
fi

# Verifica optimus-manager (se necessario)
if [[ "$NEEDS_OPTIMUS" == "true" ]]; then
    if ! command_exists optimus-manager; then
        log_error "optimus-manager non installato correttamente"
        ((ERRORS++))
    fi
fi

# --- RIEPILOGO FINALE ---
echo ""
echo "==========================================="
if [[ $ERRORS -eq 0 ]]; then
    log_success "🎉 FASE 2 COMPLETATA: YAY & OPTIMUS MANAGER"
else
    log_error "FASE 2 COMPLETATA CON $ERRORS ERRORI"
fi
echo "==========================================="
echo ""
log_info "Installato:"
echo "  ✅ yay (AUR helper)"
if [[ "$NEEDS_OPTIMUS" == "true" ]]; then
    echo "  ✅ optimus-manager (mode: $MODE)"
    echo "  ✅ optimus-manager-qt (GUI)"
    echo "  ✅ envycontrol"
fi
[[ "$GPU_TYPE" == NVIDIA_* ]] && echo "  ✅ nvidia-settings"
echo ""
log_info "Comandi utili:"
echo "  • yay -Syu                    # Aggiorna sistema + AUR"
echo "  • yay -Ss <package>           # Cerca pacchetto AUR"
if [[ "$NEEDS_OPTIMUS" == "true" ]]; then
    echo "  • optimus-manager --status    # Stato GPU attuale"
    echo "  • optimus-manager --switch nvidia   # Passa a NVIDIA"
    echo "  • optimus-manager --switch intel    # Passa a Intel"
    echo "  • optimus-manager --switch hybrid   # Modalità ibrida"
    echo "  • envycontrol -q             # Query modalità corrente"
fi
echo ""

if [[ "$NEEDS_OPTIMUS" == "true" && "$ENABLE_OPTIMUS" != "1" ]]; then
    log_warning "NOTA: Optimus Manager è installato ma non abilitato."
    log_warning "Per abilitarlo: sudo systemctl enable --now optimus-manager.service"
fi

echo "==========================================="

exit $ERRORS
