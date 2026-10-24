#!/bin/bash
# =============================================================================
# PACMASTER - Orchestratore Suite ROAD TO 100%
# =============================================================================

set -euo pipefail

# Directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
readonly SCRIPT_DIR
readonly SCRIPTS_DIR="$SCRIPT_DIR/scripts"
source "$SCRIPTS_DIR/lib/utils.sh"

# Fasi
declare -A PHASES=(
    ["1"]="01_desktop_install.sh|Desktop & Driver"
    ["2"]="02_yay_optimus.sh|Optimus Manager"
    ["3"]="03_system_tuning.sh|Tuning Performance"
    ["4"]="04_software_setup.sh|Software Stack"
    ["5"]="05_extras_setup.sh|Shell & Extras"
    ["99"]="99_safe_reboot_check.sh|Check Finale"
)

# --- Funzioni di Controllo ---

check_sudo() {
    log_info "Richiesta privilegi sudo per la sessione..."
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
}

# --- Core Logic ---

run_phase() {
    local id="$1"
    local info="${PHASES[$id]}"
    local script="${info%|*}"
    local name="${info#*|}"
    
    log_info ">>> ESECUZIONE FASE $id: $name"
    if bash "$SCRIPTS_DIR/$script"; then
        log_success "FASE $id COMPLETATA"
        return 0
    else
        log_error "FASE $id FALLITA"
        return 1
    fi
}

test_all() {
    log_info "🧪 AVVIO TEST DI INTEGRITÀ SU TUTTI GLI SCRIPT..."
    local errors=0
    for id in $(printf "%s\n" "${!PHASES[@]}" | sort -n); do
        local script="${PHASES[$id]%|*}"
        if [[ -f "$SCRIPTS_DIR/$script" ]]; then
            log_success "[OK] $script trovato"
            # Verifica base (syntax check)
            if bash -n "$SCRIPTS_DIR/$script"; then
                log_success "[OK] $script sintassi corretta"
            else
                log_error "[FAIL] $script errore sintassi"
                ((errors++))
            fi
        else
            log_error "[FAIL] $script NON TROVATO"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "✅ TEST INTEGRITÀ SUPERATO (100% COPERTURA)"
    else
        log_error "❌ RILEVATI $errors ERRORI NELLA SUITE"
        return 1
    fi
}

# --- Menu ---

show_menu() {
    clear
    echo "================================================="
    echo "    PacMaster 100% - Workstation Automator"
    echo "================================================="
    for id in $(printf "%s\n" "${!PHASES[@]}" | sort -n); do
        echo "  $id) ${PHASES[$id]#*|}"
    done
    echo "-------------------------------------------------"
    echo "  t) TEST INTEGRITÀ (Safe)"
    echo "  a) Esegui TUTTO"
    echo "  q) Esci"
    echo "================================================="
}

# --- Main ---

main() {
    if [[ "${1:-}" == "--test" ]]; then
        test_all
        exit $?
    fi

    check_sudo
    while true; do
        show_menu
        read -rp "Scelta: " cmd
        case "$cmd" in
            [1-99]) [[ -n "${PHASES[$cmd]:-}" ]] && run_phase "$cmd" ;;
            t|T) test_all ;;
            a|A) for id in $(printf "%s\n" "${!PHASES[@]}" | sort -n); do run_phase "$id" || break; done ;;
            q|Q) exit 0 ;;
        esac
        read -rp "Premi Invio..."
    done
}

main "$@"
