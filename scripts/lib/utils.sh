#!/bin/bash
# =====================================================================================
# PACUSER UTILS - ROAD TO 100% CORE LIBRARY
# =====================================================================================
# OBIETTIVO: Fornire funzioni robuste e idempotenti per l'intera suite
# VERSION: 2.0.0
# =====================================================================================

set -euo pipefail

# --- Sezione Logging ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'

log_info()    { echo -e "${C_BLUE}[INFO]${C_RESET} $1"; }
log_success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET} $1"; }
log_warning() { echo -e "${C_YELLOW}[WARNING]${C_RESET} $1"; }
log_error()   { echo -e "${C_RED}[ERROR]${C_RESET} $1" >&2; }
log_debug()   { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${C_CYAN}[DEBUG]${C_RESET} $1"; }

# --- Sezione Smart Storage ---

# Configura storage secondario (Docker e Backup)
setup_smart_storage() {
    log_info "Configurazione Smart Storage..."

    local storage_mount="/mnt/storage"
    local docker_mount="/mnt/docker"

    # Crea mount points
    sudo mkdir -p "$storage_mount" "$docker_mount"

    # Rileva HDD secondario (sda o sdb se nvme è root)
    local hdd_dev=""
    if lsblk | grep -q "sda"; then
        hdd_dev="/dev/sda"
    elif lsblk | grep -q "sdb"; then
        hdd_dev="/dev/sdb"
    fi

    if [[ -n "$hdd_dev" ]]; then
        log_info "HDD rilevato: $hdd_dev"

        # Configura /mnt/storage (sda1)
        if ! mountpoint -q "$storage_mount"; then
            if [[ -b "${hdd_dev}1" ]]; then
                sudo mount "${hdd_dev}1" "$storage_mount" || true
                update_fstab "${hdd_dev}1" "$storage_mount"
                log_success "Storage montato su $storage_mount"
            fi
        fi

        # Configura /mnt/docker (sda2)
        if ! mountpoint -q "$docker_mount"; then
            if [[ -b "${hdd_dev}2" ]]; then
                sudo mount "${hdd_dev}2" "$docker_mount" || true
                update_fstab "${hdd_dev}2" "$docker_mount"
                log_success "Docker montato su $docker_mount"
            fi
        fi
    fi

    # Crea struttura base
    if mountpoint -q "$storage_mount"; then
        sudo mkdir -p "$storage_mount"/{backups,projects,media}
        sudo chown -R "$USER:$USER" "$storage_mount"
    fi

    if mountpoint -q "$docker_mount"; then
        sudo mkdir -p "$docker_mount"/{docker-data,containerd}
        # Docker root permissions
        sudo chown root:root "$docker_mount"
        sudo chmod 755 "$docker_mount"
    fi
}

# Aggiorna fstab se entry mancante
update_fstab() {
    local dev="$1"
    local mount="$2"
    local uuid=$(sudo blkid -s UUID -o value "$dev")

    if [[ -n "$uuid" ]] && ! grep -q "$uuid" /etc/fstab; then
        echo "UUID=$uuid $mount ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
        log_success "Aggiunto $mount a fstab"
    fi
}

# --- Sezione Configurazione ---
# Carica configurazione esterna se presente
load_config() {
    local config_file="${PACUSER_CONFIG:-}"

    # Cerca config in ordine di priorità
    if [[ -z "$config_file" ]]; then
        local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        local search_paths=(
            "$script_dir/../../config/pacuser.conf"
            "$script_dir/../../pacuser.conf"
            "$HOME/.config/pacuser/pacuser.conf"
            "/etc/pacuser/pacuser.conf"
        )

        for path in "${search_paths[@]}"; do
            if [[ -f "$path" ]]; then
                config_file="$path"
                break
            fi
        done
    fi

    if [[ -n "$config_file" && -f "$config_file" ]]; then
        log_debug "Caricamento configurazione da: $config_file"
        # shellcheck source=/dev/null
        source "$config_file"
        return 0
    fi

    return 1
}

# Carica secrets se presente
load_secrets() {
    local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    local secrets_file="$script_dir/secrets.sh"

    if [[ -f "$secrets_file" ]]; then
        log_debug "Caricamento secrets..."
        # shellcheck source=/dev/null
        source "$secrets_file"
        return 0
    fi

    return 1
}

# Tenta di caricare configurazione
load_config || true
load_secrets || true

# --- Sezione Variabili di Default ---
# Queste possono essere sovrascritte da pacuser.conf
PACUSER_HOSTNAME="${PACUSER_HOSTNAME:-archlinux}"
PACUSER_USERNAME="${PACUSER_USERNAME:-$USER}"
PACUSER_TIMEZONE="${PACUSER_TIMEZONE:-Europe/Rome}"
PACUSER_LOCALE="${PACUSER_LOCALE:-it_IT.UTF-8}"
PACUSER_KEYMAP="${PACUSER_KEYMAP:-it}"
PACUSER_DOCKER_ROOT="${PACUSER_DOCKER_ROOT:-/var/lib/docker}"
PACUSER_OPTIMUS_MODE="${PACUSER_OPTIMUS_MODE:-hybrid}"
PACUSER_ENABLE_OPTIMUS_MANAGER="${PACUSER_ENABLE_OPTIMUS_MANAGER:-0}"

# --- Sezione Controlli Prerequisiti ---

# Verifica che lo script NON sia eseguito come root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Questo script NON deve essere eseguito come root!"
        log_error "Eseguilo come utente normale con privilegi sudo."
        return 1
    fi
    return 0
}

# Verifica che lo script SIA eseguito come root
check_is_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Questo script deve essere eseguito come root!"
        return 1
    fi
    return 0
}

# Verifica prerequisiti di sistema
check_system_prerequisites() {
    local errors=0

    log_info "Verifica prerequisiti di sistema..."

    # 1. Verifica connessione internet
    if ! check_internet; then
        log_error "Connessione internet assente"
        ((errors++))
    else
        log_success "Connessione internet OK"
    fi

    # 2. Verifica che siamo su Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_error "Sistema non Arch Linux rilevato"
        ((errors++))
    else
        log_success "Arch Linux rilevato"
    fi

    # 3. Verifica privilegi sudo
    if ! sudo -v &>/dev/null; then
        log_error "Privilegi sudo non disponibili"
        ((errors++))
    else
        log_success "Privilegi sudo OK"
    fi

    # 4. Verifica spazio disco (minimo 10GB su /)
    local free_space_gb
    free_space_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    if [[ $free_space_gb -lt 10 ]]; then
        log_warning "Spazio disco limitato: ${free_space_gb}GB (consigliati 10GB+)"
    else
        log_success "Spazio disco OK: ${free_space_gb}GB disponibili"
    fi

    # 5. Verifica memoria RAM (minimo 4GB)
    local ram_gb
    ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $ram_gb -lt 4 ]]; then
        log_warning "RAM limitata: ${ram_gb}GB (consigliati 4GB+)"
    else
        log_success "RAM OK: ${ram_gb}GB"
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Prerequisiti non soddisfatti ($errors errori)"
        return 1
    fi

    log_success "Tutti i prerequisiti soddisfatti"
    return 0
}

# Verifica connessione internet
check_internet() {
    ping -c 1 -W 3 archlinux.org &>/dev/null || { log_error "Internet assente"; return 1; }
    return 0
}

# Verifica permessi root (per chroot)
check_root_permissions() {
    if [[ $EUID -ne 0 ]] && ! sudo -v &>/dev/null; then
        log_error "Permessi root richiesti."
        return 1
    fi
    return 0
}

# --- Sezione Identificazione Hardware ---

detect_gpu() {
    if lspci | grep -qi "nvidia"; then
        if lspci | grep -qiE "GTX 106[0-9]|GTX 1070|GTX 1080|Pascal|GP10[0-9]"; then
            echo "NVIDIA_PASCAL"
        elif lspci | grep -qiE "GTX 9[0-9][0-9]|Maxwell|GM[0-9]"; then
            echo "NVIDIA_MAXWELL"
        else
            echo "NVIDIA_MODERN"
        fi
    elif lspci | grep -qi "amd.*radeon\|amd.*graphics"; then
        echo "AMD"
    elif lspci | grep -qi "intel"; then
        echo "INTEL"
    else
        echo "UNKNOWN"
    fi
}

detect_cpu() {
    if grep -qi "intel" /proc/cpuinfo; then
        echo "INTEL"
    elif grep -qi "amd" /proc/cpuinfo; then
        echo "AMD"
    else
        echo "UNKNOWN"
    fi
}

is_laptop() {
    # Controlla se è un laptop basandosi su vari indicatori
    if [[ -d /sys/class/power_supply/BAT0 ]] || \
       [[ -d /sys/class/power_supply/BAT1 ]] || \
       dmidecode -t chassis 2>/dev/null | grep -qi "notebook\|laptop\|portable"; then
        return 0
    fi
    return 1
}

is_lenovo_legion() {
    if dmidecode -t system 2>/dev/null | grep -qi "legion"; then
        return 0
    fi
    return 1
}

# --- Sezione Gestione Pacchetti ---

# Installa yay se mancante
install_yay() {
    if command -v yay &>/dev/null; then return 0; fi
    log_info "Installazione AUR helper (yay)..."
    local tmp="/tmp/yay-bin-$$"
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay-bin.git "$tmp"
    (cd "$tmp" && makepkg -si --noconfirm)
    rm -rf "$tmp"
}

# Verifica se un pacchetto esiste nei repository
package_exists() {
    local pkg="$1"
    pacman -Si "$pkg" &>/dev/null || yay -Si "$pkg" &>/dev/null
}

# Verifica se un pacchetto è installato
package_installed() {
    local pkg="$1"
    pacman -Qi "$pkg" &>/dev/null
}

# Wrapper universale per installazione
pacuser_install() {
    local pkg="$1"

    # Già installato
    if package_installed "$pkg"; then
        log_debug "Pacchetto già installato: $pkg"
        return 0
    fi

    log_info "Installazione: $pkg"

    # Prova prima con pacman (repo ufficiali)
    if pacman -Si "$pkg" &>/dev/null; then
        sudo pacman -S --noconfirm --needed "$pkg"
        return $?
    fi

    # Altrimenti usa yay (AUR)
    install_yay
    if yay -Si "$pkg" &>/dev/null; then
        yay -S --noconfirm --needed "$pkg"
        return $?
    fi

    log_error "Pacchetto non trovato: $pkg"
    return 1
}

# Installazione batch di pacchetti
pacuser_install_batch() {
    local packages=("$@")
    local failed=()

    for pkg in "${packages[@]}"; do
        if ! pacuser_install "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warning "Pacchetti non installati: ${failed[*]}"
        return 1
    fi

    return 0
}

# Rimuove pacchetto se installato
pacuser_remove() {
    local pkg="$1"

    if package_installed "$pkg"; then
        log_info "Rimozione: $pkg"
        sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null || true
    fi
}

# --- Sezione Configurazione ---

# Aggiorna o aggiunge una configurazione in un file
# Usage: update_config "/path/file" "KEY" "KEY=value" [use_sudo]
update_config() {
    local file="$1"
    local key="$2"
    local line="$3"
    local use_sudo="${4:-false}"

    local cmd=""
    [[ "$use_sudo" == "true" ]] && cmd="sudo"

    # Crea file e directory se non esistono
    if [[ ! -f "$file" ]]; then
        $cmd mkdir -p "$(dirname "$file")"
        $cmd touch "$file"
    fi

    # Aggiorna o aggiungi la linea
    if grep -q "^[#]*\s*$key" "$file" 2>/dev/null; then
        $cmd sed -i "s|^[#]*\s*$key.*|$line|" "$file"
    else
        echo "$line" | $cmd tee -a "$file" > /dev/null
    fi
}

# Aggiunge una linea se non esiste già
append_if_missing() {
    local file="$1"
    local line="$2"
    local use_sudo="${3:-false}"

    local cmd=""
    [[ "$use_sudo" == "true" ]] && cmd="sudo"

    if ! grep -qF "$line" "$file" 2>/dev/null; then
        echo "$line" | $cmd tee -a "$file" > /dev/null
    fi
}

# --- Sezione Servizi Systemd ---

# Abilita e opzionalmente avvia un servizio
enable_service() {
    local svc="$1"
    local start="${2:-true}"

    if ! systemctl is-enabled "$svc" &>/dev/null; then
        log_info "Abilitazione servizio: $svc"
        sudo systemctl enable "$svc"
    fi

    if [[ "$start" == "true" ]] && ! systemctl is-active "$svc" &>/dev/null; then
        log_info "Avvio servizio: $svc"
        sudo systemctl start "$svc"
    fi
}

# Disabilita e ferma un servizio
disable_service() {
    local svc="$1"

    if systemctl is-active "$svc" &>/dev/null; then
        log_info "Stop servizio: $svc"
        sudo systemctl stop "$svc"
    fi

    if systemctl is-enabled "$svc" &>/dev/null; then
        log_info "Disabilitazione servizio: $svc"
        sudo systemctl disable "$svc"
    fi
}

# Riavvia un servizio
restart_service() {
    local svc="$1"
    log_info "Riavvio servizio: $svc"
    sudo systemctl restart "$svc"
}

# --- Sezione Backup ---

# Crea backup di un file prima di modificarlo
backup_file() {
    local file="$1"
    local backup_dir="${2:-/tmp/pacuser_backups}"

    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        local backup_name
        backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$backup_dir/$backup_name"
        log_debug "Backup creato: $backup_dir/$backup_name"
    fi
}

# --- Sezione Utilità ---

# Chiede conferma all'utente
confirm() {
    local message="${1:-Continuare?}"
    local default="${2:-n}"

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    read -rp "$message $prompt " response
    response="${response:-$default}"

    [[ "$response" =~ ^[Yy]$ ]]
}

# Attende N secondi con countdown
wait_countdown() {
    local seconds="${1:-5}"
    local message="${2:-Attendi}"

    for ((i=seconds; i>0; i--)); do
        echo -ne "\r$message: $i secondi...  "
        sleep 1
    done
    echo ""
}

# Verifica se un comando esiste
command_exists() {
    command -v "$1" &>/dev/null
}

# Ottiene il percorso dello script corrente
get_script_dir() {
    cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd
}

# --- Wrapper per Compatibilità Root/User ---
if [ "$EUID" -eq 0 ]; then
    sudo() { "$@"; }
fi

# --- Export Variabili ---
export PACUSER_HOSTNAME
export PACUSER_USERNAME
export PACUSER_TIMEZONE
export PACUSER_LOCALE
export PACUSER_KEYMAP
export PACUSER_DOCKER_ROOT
export PACUSER_OPTIMUS_MODE
export PACUSER_ENABLE_OPTIMUS_MANAGER
