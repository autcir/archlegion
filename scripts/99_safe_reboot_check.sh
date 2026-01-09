#!/bin/bash
# =============================================================================
# PACUSER FASE 99: FINAL SAFETY CHECK
# =============================================================================

# Caricamento libreria utils
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/lib/utils.sh"

log_info "🔍 ESECUZIONE CHECK FINALE DI SICUREZZA..."
ERRORS=0

# 1. KERNEL & INITRAMFS
log_info "Verifica Kernel e Initramfs..."
GPU=$(detect_gpu)
if [[ "$GPU" == "NVIDIA_PASCAL" ]]; then
    KERNEL="linux-lts"
else
    KERNEL="linux"
fi

if [[ -f "/boot/vmlinuz-$KERNEL" ]] && [[ -f "/boot/initramfs-$KERNEL.img" ]]; then
    log_success "Kernel $KERNEL trovato."
else
    log_error "Kernel $KERNEL mancante! Rigenero initramfs..."
    sudo mkinitcpio -P || ((ERRORS++))
fi

# 2. BOOTLOADER
log_info "Verifica GRUB..."
if [[ -f /boot/grub/grub.cfg ]] && grep -q "linux" /boot/grub/grub.cfg; then
    log_success "GRUB configurato."
else
    log_error "GRUB invalido!"
    sudo grub-mkconfig -o /boot/grub/grub.cfg || ((ERRORS++))
fi

# 3. DRIVER NVIDIA (DKMS)
log_info "Verifica NVIDIA..."
if dkms status | grep -q "nvidia"; then
    log_success "Moduli NVIDIA registrati."
else
    log_warning "Moduli NVIDIA non registrati! Tento compilazione..."
    sudo dkms autoinstall || ((ERRORS++))
fi

# 4. FSTAB
log_info "Verifica FSTAB..."
sudo mount -a --fake || ((ERRORS++))

# 5. SERVIZI CRITICI
for s in sddm NetworkManager docker; do
    if systemctl is-enabled "$s" &>/dev/null; then
        log_info "Servizio $s: OK"
    else
        log_warning "Abilitazione $s..."
        enable_service "$s" false
    fi
done

# REPORT
echo "----------------------------------------------------"
if [[ $ERRORS -eq 0 ]]; then
    log_success "✅ SISTEMA PRONTO PER IL RIAVVIO ✅"
else
    log_error "❌ RILEVATI $ERRORS ERRORI CRITICI - NON RIAVVIARE ❌"
fi
echo "----------------------------------------------------"
