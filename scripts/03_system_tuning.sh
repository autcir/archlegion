#!/bin/bash

# =============================================================================
# PACUSER FASE 3: OTTIMIZZAZIONI SISTEMA (DEVOPS + SECURITY EDITION)
# =============================================================================
# OBIETTIVO: Configurazione sistema per sviluppo, containerizzazione e sicurezza
#            - TLP per gestione energetica (bilanciato)
#            - Intel Undervolt per temperature
#            - ZRAM per gestione memoria efficiente
#            - Tuning Kernel per Docker/IDE (inotify, file limits)
#            - Networking ottimizzato (BBR)
#            - UFW Firewall
#            - Fail2Ban protezione brute-force
# ESECUZIONE: ./03_system_tuning.sh
# PREREQUISITI: Fase 2 completata
# VERSION: 2.0.0
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

# Verifica prerequisiti
check_system_prerequisites || exit 1
check_not_root

log_info "🚀 AVVIO FASE 3: SYSTEM TUNING & SECURITY"

# --- FASE 1: POWER & PERFORMANCE ---
log_info "⚡ Ottimizzazione Power Management..."

PKGS_POWER=("tlp" "tlp-rdw" "powertop" "cpupower" "irqbalance" "thermald" "ananicy-cpp")
for p in "${PKGS_POWER[@]}"; do
    pacuser_install "$p"
done

enable_service "cpupower.service"
enable_service "irqbalance.service"
enable_service "thermald.service"
enable_service "ananicy-cpp.service"
enable_service "tlp.service"

# Configura Governor
CPU_GOVERNOR="${PACUSER_CPU_GOVERNOR:-performance}"
update_config "/etc/default/cpupower" "GOVERNOR" "GOVERNOR='$CPU_GOVERNOR'" true
sudo cpupower frequency-set -g "$CPU_GOVERNOR" 2>/dev/null || true
log_success "CPU Governor impostato: $CPU_GOVERNOR"

# --- FASE 2: INTEL UNDERVOLT ---
ENABLE_UNDERVOLT="${PACUSER_ENABLE_UNDERVOLT:-1}"
CPU_TYPE=$(detect_cpu)

if [[ "$ENABLE_UNDERVOLT" == "1" ]] && [[ "$CPU_TYPE" == "INTEL" ]]; then
    if pacuser_install "intel-undervolt"; then
        log_info "🌡️ Configurazione Intel Undervolt..."

        UV_CPU="${PACUSER_UNDERVOLT_CPU:--80}"
        UV_GPU="${PACUSER_UNDERVOLT_GPU:--80}"
        UV_CACHE="${PACUSER_UNDERVOLT_CACHE:--80}"

        sudo tee /etc/intel-undervolt.conf >/dev/null <<EOF
# PACUSER Intel Undervolt Configuration
# Valori in mV (negativi = sottovolt)
# ATTENZIONE: Valori troppo aggressivi possono causare instabilità

undervolt 0 'CPU' $UV_CPU
undervolt 1 'GPU' $UV_GPU
undervolt 2 'CPU Cache' $UV_CACHE

# Intervallo di applicazione (ms)
interval 300000

# Esegui come daemon
daemon yes
EOF
        enable_service "intel-undervolt.service"
        log_success "Intel Undervolt configurato: CPU=$UV_CPU, GPU=$UV_GPU, Cache=$UV_CACHE"
    fi
else
    log_info "Intel Undervolt saltato (CPU=$CPU_TYPE, ENABLE=$ENABLE_UNDERVOLT)"
fi

# --- FASE 3: KERNEL TUNING (DEVOPS) ---
log_info "🛠️ Tuning Kernel (Inotify, Network, Swap)..."

sudo tee /etc/sysctl.d/99-pacuser-tuning.conf >/dev/null <<EOF
# =============================================================================
# PACUSER KERNEL TUNING - DevOps Edition
# =============================================================================

# --- IDE & File Watchers ---
# Aumenta limite watcher per VSCode, WebStorm, ecc.
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192

# --- Docker & Container Limits ---
fs.file-max = 2097152
vm.max_map_count = 262144

# --- Memory & Swap ---
# Riduci uso swap (abbiamo RAM sufficiente)
vm.swappiness = 10
# Mantieni cache filesystem più a lungo
vm.vfs_cache_pressure = 50
# Scrivi su disco prima per evitare spike I/O
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# --- Network (BBR + CAKE) ---
# Algoritmo di coda CAKE (migliore per latenza)
net.core.default_qdisc = cake
# BBR congestion control (Google)
net.ipv4.tcp_congestion_control = bbr
# TCP Fast Open (riduce latenza connessioni)
net.ipv4.tcp_fastopen = 3

# --- Network Buffers ---
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# --- Security (Base) ---
# Ignora ICMP broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Protezione SYN flood
net.ipv4.tcp_syncookies = 1
# Ignora redirect ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
EOF

sudo sysctl --system >/dev/null
log_success "Parametri kernel applicati"

# --- FASE 4: ZRAM & LIMITS ---
ENABLE_ZRAM="${PACUSER_ENABLE_ZRAM:-1}"

if [[ "$ENABLE_ZRAM" == "1" ]]; then
    log_info "💾 Configurazione ZRAM..."

    pacuser_install "zram-generator"

    ZRAM_SIZE="${PACUSER_ZRAM_SIZE:-ram / 2}"
    ZRAM_ALGO="${PACUSER_ZRAM_ALGORITHM:-zstd}"

    sudo tee /etc/systemd/zram-generator.conf >/dev/null <<EOF
# PACUSER ZRAM Configuration
[zram0]
zram-size = $ZRAM_SIZE
compression-algorithm = $ZRAM_ALGO
EOF

    sudo systemctl daemon-reload
    enable_service "systemd-zram-setup@zram0.service"
    log_success "ZRAM configurato: size=$ZRAM_SIZE, algorithm=$ZRAM_ALGO"
fi

# Ulimits per Docker/IDE
log_info "📊 Configurazione ulimits..."
sudo tee /etc/security/limits.d/99-pacuser.conf >/dev/null <<EOF
# PACUSER Ulimits - DevOps Workstation
# Necessari per Docker, IDE, e applicazioni heavy

# File descriptors
* soft nofile 65536
* hard nofile 1048576

# Processi
* soft nproc unlimited
* hard nproc unlimited

# Memory lock (per applicazioni che usano mlock)
* soft memlock unlimited
* hard memlock unlimited
EOF
log_success "Ulimits configurati"

# --- FASE 5: SICUREZZA - UFW FIREWALL ---
ENABLE_UFW="${PACUSER_ENABLE_UFW:-1}"

if [[ "$ENABLE_UFW" == "1" ]]; then
    log_info "🔒 Configurazione UFW Firewall..."

    pacuser_install "ufw"

    # Configurazione base
    sudo ufw --force reset >/dev/null 2>&1 || true

    # Policy di default: blocca tutto in ingresso, consenti uscite
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Porte da aprire (da config)
    UFW_PORTS="${PACUSER_UFW_ALLOW_PORTS:-22}"

    for port in $UFW_PORTS; do
        sudo ufw allow "$port"
        log_info "  → Porta $port aperta"
    done

    # Regole aggiuntive comuni per DevOps
    # HTTP/HTTPS per sviluppo locale
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'

    # Range porte sviluppo locale (3000-9999)
    sudo ufw allow 3000:3999/tcp comment 'Dev servers (React, Node, etc)'
    sudo ufw allow 8000:8999/tcp comment 'Dev servers (Django, FastAPI, etc)'

    # Docker (solo localhost)
    sudo ufw allow from 172.16.0.0/12 comment 'Docker networks'

    # Kubernetes locale
    sudo ufw allow 6443/tcp comment 'Kubernetes API'
    sudo ufw allow 10250/tcp comment 'Kubelet'

    # Abilita UFW
    sudo ufw --force enable

    log_success "UFW Firewall abilitato e configurato"

    # Mostra status
    sudo ufw status verbose
else
    log_warning "UFW Firewall non abilitato (PACUSER_ENABLE_UFW=0)"
fi

# --- FASE 6: SICUREZZA - FAIL2BAN ---
ENABLE_FAIL2BAN="${PACUSER_ENABLE_FAIL2BAN:-1}"

if [[ "$ENABLE_FAIL2BAN" == "1" ]]; then
    log_info "🛡️ Configurazione Fail2Ban..."

    pacuser_install "fail2ban"

    # Configurazione jail locale
    sudo mkdir -p /etc/fail2ban/jail.d

    sudo tee /etc/fail2ban/jail.d/pacuser.local >/dev/null <<EOF
# =============================================================================
# PACUSER Fail2Ban Configuration
# =============================================================================

[DEFAULT]
# Ban IP per 1 ora dopo 5 tentativi falliti in 10 minuti
bantime = 3600
findtime = 600
maxretry = 5

# Ignora localhost e reti private
ignoreip = 127.0.0.1/8 ::1 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

# Backend auto-detect
backend = auto

# Azione: ban con UFW (se disponibile) altrimenti iptables
banaction = ufw

# Email notification (disabilitato di default)
# destemail = admin@example.com
# sender = fail2ban@localhost
# action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200

# Protezione aggressiva per SSH
[sshd-aggressive]
enabled = true
port = ssh
filter = sshd[mode=aggressive]
logpath = /var/log/auth.log
maxretry = 2
bantime = 86400
EOF

    # Crea directory log se non esiste (Arch usa journald)
    if [[ ! -f /var/log/auth.log ]]; then
        log_info "Configurazione rsyslog per auth.log..."

        # Installa rsyslog se necessario per i log
        if pacuser_install "rsyslog"; then
            sudo tee /etc/rsyslog.d/50-auth.conf >/dev/null <<EOF
# Log autenticazione per Fail2Ban
auth,authpriv.*                 /var/log/auth.log
EOF
            enable_service "rsyslog.service"
        fi
    fi

    enable_service "fail2ban.service"

    log_success "Fail2Ban abilitato"

    # Mostra status
    sleep 2
    sudo fail2ban-client status 2>/dev/null || true
else
    log_warning "Fail2Ban non abilitato (PACUSER_ENABLE_FAIL2BAN=0)"
fi

# --- FASE 7: AUDIT SICUREZZA (OPZIONALE) ---
log_info "📋 Installazione tool audit sicurezza..."

# Lynis per audit di sicurezza
if pacuser_install "lynis"; then
    log_success "Lynis installato. Esegui 'sudo lynis audit system' per audit completo"
fi

# ClamAV antivirus (opzionale, commentato di default)
# pacuser_install "clamav"
# sudo freshclam
# enable_service "clamav-freshclam.service"

# --- FASE 8: TLP CONFIGURAZIONE AVANZATA ---
log_info "🔋 Configurazione TLP avanzata..."

if is_laptop; then
    sudo tee /etc/tlp.d/99-pacuser.conf >/dev/null <<EOF
# =============================================================================
# PACUSER TLP Configuration - Laptop Optimization
# =============================================================================

# --- CPU ---
# Performance su AC, Powersave su batteria
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# Boost CPU
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Energy Performance Preference
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# --- NVIDIA ---
# Runtime PM per GPU NVIDIA (hybrid mode)
RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# --- Dischi ---
DISK_DEVICES="nvme0n1 sda"
DISK_APM_LEVEL_ON_AC="254 254"
DISK_APM_LEVEL_ON_BAT="128 128"

# --- USB ---
USB_AUTOSUSPEND=1
USB_EXCLUDE_BTUSB=1

# --- WiFi ---
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# --- Battery Charge Thresholds (se supportato) ---
# Lenovo Legion
# START_CHARGE_THRESH_BAT0=75
# STOP_CHARGE_THRESH_BAT0=80
EOF

    # Riavvia TLP per applicare
    sudo tlp start 2>/dev/null || true
    log_success "TLP configurato per laptop"
else
    log_info "TLP: configurazione desktop (skip ottimizzazioni batteria)"
fi

# --- RIEPILOGO FINALE ---
echo ""
echo "==========================================="
log_success "🎉 FASE 3 COMPLETATA: SYSTEM TUNING & SECURITY"
echo "==========================================="
echo ""
log_info "Configurazioni applicate:"
echo "  ✅ Power Management (TLP, cpupower, thermald)"
[[ "$CPU_TYPE" == "INTEL" && "$ENABLE_UNDERVOLT" == "1" ]] && echo "  ✅ Intel Undervolt ($UV_CPU mV)"
echo "  ✅ Kernel Tuning (inotify, BBR, swap)"
[[ "$ENABLE_ZRAM" == "1" ]] && echo "  ✅ ZRAM ($ZRAM_SIZE, $ZRAM_ALGO)"
echo "  ✅ Ulimits (nofile, nproc)"
[[ "$ENABLE_UFW" == "1" ]] && echo "  ✅ UFW Firewall"
[[ "$ENABLE_FAIL2BAN" == "1" ]] && echo "  ✅ Fail2Ban (SSH protection)"
echo "  ✅ Lynis (security audit tool)"
echo ""
log_info "Comandi utili:"
echo "  • sudo ufw status          # Stato firewall"
echo "  • sudo fail2ban-client status  # Stato ban"
echo "  • sudo lynis audit system  # Audit sicurezza"
echo "  • sudo tlp-stat            # Stato power management"
echo ""
echo "==========================================="
