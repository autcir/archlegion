#!/bin/bash
# =============================================================================
# PACMASTER WRAPPER
# =============================================================================
# Questo script è un wrapper per avviare pacmaster dalla root del repository.
# Punta allo script reale in app/pacmaster.sh
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REAL_SCRIPT="$SCRIPT_DIR/app/pacmaster.sh"

if [[ -f "$REAL_SCRIPT" ]]; then
    chmod +x "$REAL_SCRIPT"
    exec "$REAL_SCRIPT" "$@"
else
    echo "❌ Errore: Impossibile trovare $REAL_SCRIPT"
    echo "Assicurati che la struttura del repository sia corretta."
    exit 1
fi
