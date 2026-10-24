#!/bin/bash

# =============================================================================
# FASE 0: CONFIGURAZIONE DI BASE NEL CHROOT
# =============================================================================
# ESECUZIONE: Eseguire questo script come root all'interno dell'ambiente chroot.
#
# OBIETTIVO: Automatizzare i primi passaggi di configurazione di Arch Linux,
#            rendendo il sistema avviabile e pronto per la configurazione
#            dell'ambiente desktop.
# VERSION: 2.0.0
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica se siamo root (necessario per chroot)
check_root_permissions || exit 1

# --- Variabili di Configurazione (da pacuser.conf) ---
TIMEZONE="${PACUSER_TIMEZONE:-Europe/Rome}"
LOCALE_LANG="${PACUSER_LOCALE:-it_IT.UTF-8}"
KEYMAP="${PACUSER_KEYMAP:-it}"
HOSTNAME="${PACUSER_HOSTNAME:-archlinux}"

# Username: usa config, oppure chiedi interattivamente
if [[ -n "${PACUSER_USERNAME:-}" ]]; then
    NOME_UTENTE="$PACUSER_USERNAME"
else
    read -rp "Inserisci il nome utente da creare: " NOME_UTENTE
    if [[ -z "$NOME_UTENTE" ]]; then
        log_error "Nome utente non può essere vuoto"
        exit 1
    fi
fi

# Gruppi utente
GRUPPI="${PACUSER_USER_GROUPS:-wheel,storage,power,audio,video,network,lp,sys,adm,optical,scanner,users,rfkill,input,uucp,disk,tty,games,render,kvm}"

log_info "=== INIZIO CONFIGURAZIONE DI BASE (CHROOT) ==="
log_info "Hostname: $HOSTNAME"
log_info "Utente: $NOME_UTENTE"
log_info "Timezone: $TIMEZONE"
log_info "Locale: $LOCALE_LANG"
log_info "Keymap: $KEYMAP"

# --- 1. Fuso Orario, Locale e Tastiera ---
log_info "Configurazione di fuso orario, locale e tastiera..."

# Configurazione timezone
if [[ ! -L /etc/localtime ]] || [[ "$(readlink /etc/localtime)" != "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    log_info "Impostazione timezone: $TIMEZONE"
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
    hwclock --systohc
    log_success "Timezone configurato"
else
    log_info "Timezone già configurato correttamente"
fi

# Configurazione locale
if ! grep -q "^$LOCALE_LANG UTF-8" /etc/locale.gen 2>/dev/null; then
    log_info "Abilitazione locale: $LOCALE_LANG"
    sed -i "s/^#$LOCALE_LANG UTF-8/$LOCALE_LANG UTF-8/" /etc/locale.gen
    # Abilita anche en_US.UTF-8 come fallback
    sed -i "s/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
    locale-gen
    log_success "Locale generato"
else
    log_info "Locale già abilitato"
fi

# Configurazione LANG
update_config "/etc/locale.conf" "LANG" "LANG=$LOCALE_LANG" true

# Configurazione tastiera console
update_config "/etc/vconsole.conf" "KEYMAP" "KEYMAP=$KEYMAP" true

# --- 2. Rete ---
log_info "Configurazione della rete e del nome host: $HOSTNAME"

# Configurazione hostname
echo "$HOSTNAME" > /etc/hostname
log_success "Hostname configurato: $HOSTNAME"

# Configurazione hosts
if ! grep -q "$HOSTNAME" /etc/hosts 2>/dev/null; then
    log_info "Configurazione file hosts"
    cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain    $HOSTNAME
EOF
    log_success "File hosts configurato"
else
    log_info "File hosts già configurato"
fi

# --- 3. Password di Root ---
log_info "Configurazione password di root"
log_warning "Impostazione della password di root (richiesto input):"
passwd

# --- 4. Creazione Utente ---
log_info "Configurazione utente: $NOME_UTENTE"

if ! id "$NOME_UTENTE" &>/dev/null; then
    log_info "Creazione utente '$NOME_UTENTE'..."
    useradd -m -G "$GRUPPI" -s /bin/bash "$NOME_UTENTE"
    log_warning "Imposta password per '$NOME_UTENTE':"
    passwd "$NOME_UTENTE"
    log_success "Utente '$NOME_UTENTE' creato"
else
    log_info "Utente '$NOME_UTENTE' esistente, aggiorno gruppi..."
    usermod -a -G "$GRUPPI" "$NOME_UTENTE"
fi

# --- 5. Configurazione Sudo ---
log_info "Configurazione privilegi sudo..."
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel-sudo
chmod 440 /etc/sudoers.d/10-wheel-sudo
log_success "Sudo configurato per gruppo wheel"

# --- 6. Installazione Bootloader (GRUB) ---
log_info "Configurazione bootloader GRUB..."

# Installa pacchetti necessari
pacman -S --noconfirm --needed grub efibootmgr

# Installa GRUB se non già presente
if [[ ! -d /boot/grub ]]; then
    log_info "Installazione GRUB su EFI..."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    log_success "GRUB installato"
else
    log_info "GRUB già installato, rigenero configurazione..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- 7. Abilitazione Servizi Essenziali ---
log_info "Abilitazione servizi essenziali..."

# NetworkManager
if pacman -Q networkmanager &>/dev/null; then
    systemctl enable NetworkManager.service
    log_success "NetworkManager abilitato"
else
    log_warning "NetworkManager non installato, installazione..."
    pacman -S --noconfirm --needed networkmanager
    systemctl enable NetworkManager.service
fi

# --- 8. Performance Tuning Base ---
log_info "Applicazione performance tuning base..."

# Installa pacchetti performance
log_info "Installazione pacchetti performance..."
pacman -S --noconfirm --needed cpupower irqbalance thermald powertop

# Abilita servizi performance
systemctl enable cpupower.service
systemctl enable irqbalance.service
systemctl enable thermald.service

# Imposta governor
CPU_GOVERNOR="${PACUSER_CPU_GOVERNOR:-performance}"
mkdir -p /etc/default
echo "GOVERNOR='$CPU_GOVERNOR'" > /etc/default/cpupower
log_success "CPU Governor impostato: $CPU_GOVERNOR"

# Sysctl tuning base
SYSCTL_FILE="/etc/sysctl.d/90-base-performance.conf"
if [[ ! -f "$SYSCTL_FILE" ]]; then
    log_info "Configurazione sysctl base..."
    cat <<'EOF' > "$SYSCTL_FILE"
# Base Performance Tuning (chroot setup)
# NOTA: 03_system_tuning.sh aggiunge configurazioni aggiuntive

# Networking base
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3

# File system
fs.file-max = 2097152
EOF
    log_success "Sysctl base configurato"
fi

# Modulo CAKE per networking
echo "sch_cake" > /etc/modules-load.d/cake.conf 2>/dev/null || true

# Udev rule NVMe (se presente)
NVME_DEV=$(lsblk -dno NAME | grep -E '^nvme' | head -n1)
if [[ -n "$NVME_DEV" ]]; then
    RULE_FILE="/etc/udev/rules.d/60-nvme-io-scheduler.rules"
    if [[ ! -f "$RULE_FILE" ]]; then
        log_info "Configurazione I/O scheduler per NVMe..."
        cat <<EOF > "$RULE_FILE"
ACTION=="add|change", KERNEL=="$NVME_DEV", ATTR{queue/scheduler}="mq-deadline", ATTR{queue/rq_affinity}="2"
EOF
        log_success "NVMe I/O scheduler configurato"
    fi
fi

# --- 9. Disattivazione Servizi Non Necessari ---
log_info "Disattivazione servizi non necessari..."
# Disattivazione servizi non necessari di default (opzionale)
# shellcheck disable=SC2043  # lista di un elemento: si estende aggiungendo servizi
for svc in cups.service; do
    if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        systemctl disable "$svc" 2>/dev/null || true
        log_info "Disabilitato: $svc"
    fi
done

# --- 10. Smart Storage Setup ---
log_info "Configurazione Smart Storage (fstab)..."

# Configura mount point
mkdir -p /mnt/storage /mnt/docker

# Rileva UUID dischi secondari (sda1/sda2 su configurazione standard Legion)
UUID_STORAGE=$(blkid -s UUID -o value /dev/sda1 2>/dev/null || true)
UUID_DOCKER=$(blkid -s UUID -o value /dev/sda2 2>/dev/null || true)

if [[ -n "$UUID_STORAGE" ]]; then
    if ! grep -q "$UUID_STORAGE" /etc/fstab; then
        echo "UUID=$UUID_STORAGE /mnt/storage ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
        log_success "Aggiunto /mnt/storage a fstab"
    fi
fi

if [[ -n "$UUID_DOCKER" ]]; then
    if ! grep -q "$UUID_DOCKER" /etc/fstab; then
        echo "UUID=$UUID_DOCKER /mnt/docker ext4 defaults,noatime,nofail 0 2" >> /etc/fstab
        log_success "Aggiunto /mnt/docker a fstab"
    fi
fi

# Configura /opt offload per risparmiare spazio su root (preparazione)
OPT_OFFLOAD="/home/$NOME_UTENTE/opt-offload"
mkdir -p "$OPT_OFFLOAD"
chown "$NOME_UTENTE:$NOME_UTENTE" "/home/$NOME_UTENTE"

if ! grep -q "$OPT_OFFLOAD" /etc/fstab; then
    echo "# PACUSER: /opt offload to /home" >> /etc/fstab
    echo "$OPT_OFFLOAD /opt none bind 0 0" >> /etc/fstab
    log_success "Configurato offload /opt -> /home"
fi

# --- 11. Riepilogo ---
echo ""
echo "==========================================="
log_success "CONFIGURAZIONE CHROOT COMPLETATA"
echo "==========================================="
log_info "Sistema configurato con:"
echo "  • Hostname: $HOSTNAME"
echo "  • Utente: $NOME_UTENTE (con privilegi sudo)"
echo "  • Timezone: $TIMEZONE"
echo "  • Locale: $LOCALE_LANG"
echo "  • Keymap: $KEYMAP"
echo "  • Bootloader: GRUB (UEFI)"
echo "  • Servizi: NetworkManager, cpupower, irqbalance, thermald"
echo ""
log_warning "Prossimi passi:"
echo "  1. Esci dal chroot: exit"
echo "  2. Smonta le partizioni: umount -R /mnt"
echo "  3. Riavvia il sistema: reboot"
echo "  4. Dopo il riavvio, esegui: ./pacmaster.sh"
echo ""
echo "==========================================="
