#!/bin/bash
# =============================================================================
# PACUSER FASE 5: SHELL, UTILS & ESTETICA
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica prerequisiti
check_system_prerequisites || exit 1
check_not_root

log_info "🚀 AVVIO FASE 5: EXTRAS & PERSONALIZZAZIONE"

# --- FASE 1: UTILITY SISTEMA ---
log_info "🛠️ Installazione utility sistema..."
PKGS_UTILS=("fastfetch" "nvtop" "btop" "zoxide" "starship" "proton-vpn-gtk-app" "paccache")
for p in "${PKGS_UTILS[@]}"; do pacuser_install "$p"; done

# --- FASE 2: SHELL CONFIG (BASH) ---
log_info "🐚 Configurazione Bash & Starship..."
BASHRC="$HOME/.bashrc"
update_config "$BASHRC" "starship init bash" 'eval "$(starship init bash)"'
update_config "$BASHRC" "zoxide init bash" 'eval "$(zoxide init bash)"'

# Starship Config
mkdir -p "$HOME/.config"
if [[ -f "$SCRIPT_DIR/../config/starship.toml" ]]; then
    cp "$SCRIPT_DIR/../config/starship.toml" "$HOME/.config/starship.toml"
fi

# --- FASE 3: ALIAS DEVOPS ---
log_info "⌨️ Configurazione Alias..."
ALIAS_FILE="$HOME/.bash_aliases"
cat > "$ALIAS_FILE" <<'EOF'
# PACUSER DEVOPS ALIASES
alias update="sudo pacman -Syu && yay -Syu"
alias ls="ls --color=auto"
alias ll="ls -l --color=auto"
alias la="ls -la --color=auto"
alias cat="bat"
alias grep="rg"
alias ..="cd .."
alias g="git"
alias d="docker"
alias dc="docker-compose"
alias k="kubectl"
alias sysinfo="fastfetch"
alias gpu="nvtop"
EOF
update_config "$BASHRC" "bash_aliases" "[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases"

# --- FASE 4: ESTETICA (ICONE KORA) ---
ICON_ARCHIVE="$SCRIPT_DIR/../utility/format/kora-yellow-2-0-0.tar.xz"
if [[ -f "$ICON_ARCHIVE" ]]; then
    log_info "📦 Installazione icone Kora Yellow..."
    sudo mkdir -p /usr/share/icons
    sudo tar -xvf "$ICON_ARCHIVE" -C /usr/share/icons/ >/dev/null
    log_success "Icone installate in /usr/share/icons/kora-yellow"
fi

# --- FASE 5: MANUTENZIONE ---
log_info "🧹 Configurazione manutenzione automatica..."
sudo journalctl --vacuum-size=100M
update_config "/etc/systemd/journald.conf" "SystemMaxUse" "SystemMaxUse=100M" true

log_success "🎉 FASE 5 COMPLETATA!"
