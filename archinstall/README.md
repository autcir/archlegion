# 🏗️ Archinstall Personalizzato - PACUSER DevOps

Configurazione personalizzata per `archinstall` che automatizza l'installazione base di Arch Linux.

## 📁 File

| File | Descrizione |
|------|-------------|
| `user_configuration.json` | Configurazione sistema (locale, desktop, driver) |
| `user_credentials.json` | Credenziali utente (da modificare!) |
| `disk_config.json` | Configurazione dischi (generata da archinstall) |

## 🚀 Utilizzo

### 1. Boot da ISO Arch Linux

### 2. Connetti a Internet
```bash
# WiFi
iwctl station wlan0 connect "SSID"

# Oppure Ethernet (automatico)
```

### 3. Copia i file di configurazione
```bash
# Da USB o rete
mkdir -p /root/archinstall
# Copia user_configuration.json e user_credentials.json
```

### 4. Modifica le credenziali
```bash
nano /root/archinstall/user_credentials.json
# Imposta password root e utente
```

### 5. Esegui archinstall con configurazione
```bash
archinstall --config /root/archinstall/user_configuration.json \
            --creds /root/archinstall/user_credentials.json
```

### 6. Segui il wizard per i dischi
Archinstall chiederà di configurare i dischi manualmente o automaticamente.

### 7. Dopo l'installazione
```bash
# Riavvia
reboot

# Dopo il login, esegui gli script PACUSER
cd /path/to/pacuser
./pacmaster.sh
```

## ⚙️ Cosa viene installato

- **Kernel**: linux
- **Bootloader**: GRUB (UEFI)
- **Desktop**: KDE Plasma
- **Display Manager**: SDDM
- **Audio**: PipeWire
- **Network**: NetworkManager
- **Driver GPU**: NVIDIA proprietary
- **Locale**: Italiano (it_IT.UTF-8)
- **Timezone**: Europe/Rome
- **Tastiera**: IT

## 📝 Note

- I file `user_credentials.json` contengono placeholder per le password
- **NON committare mai file con password reali su Git**
- La configurazione dei dischi va fatta durante l'installazione
- Dopo il primo boot, esegui `pacmaster.sh` per completare la configurazione

## 🔗 Workflow Completo

```
1. Boot ISO Arch → archinstall con config
2. Primo boot → Login KDE
3. Esegui pacmaster.sh → Tutte le fasi
4. Riavvia → Sistema DevOps pronto!
```
