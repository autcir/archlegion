# 🖥️ Arch Linux Installation Guide for Lenovo Legion Y520

> **Complete workstation setup for DevOps, Cloud Engineering, and Development**

This repository contains a comprehensive guide to install and configure **Arch Linux** on the **Lenovo Legion Y520** laptop. The setup is optimized for professional development work with full GPU support (NVIDIA Optimus), security hardening, and DevOps tools.

---

## 📚 Documentation Structure

This repository is organized into several sections covering different aspects of the installation and configuration:

### 🏗️ Installation Guides

| Document | Description |
|----------|-------------|
| [`README.md`](#installation-guide) | Base Arch Linux installation (this document) |
| [`01-desktop.md`](01-desktop.md) | Desktop environment (Xorg, XFCE/KDE, NVIDIA, Optimus Manager) |
| [`02-utils.md`](02-utils.md) | System utilities, Zsh, optimizations, power management |
| [`03-software.md`](03-software.md) | Essential applications, Steam, VirtualBox, Wine |

### 🔧 Software Configuration

| Document | Description |
|----------|-------------|
| [`software/postgress.md`](software/postgress.md) | PostgreSQL installation and remote access |
| [`software/postgress_tips.md`](software/postgress_tips.md) | PostgreSQL users, databases, and roles management |
| [`software/gnome_keyring.md`](software/gnome_keyring.md) | GNOME Keyring for secure password storage |
| [`software/droid_cam.md`](software/droid_cam.md) | Virtual webcam setup with DroidCam |
| [`software/rclone.md`](software/rclone.md) | Rclone with Google Drive mount |

### 🚀 PACUSER Suite

The PACUSER scripts are located in the [`../scripts/`](../scripts/) directory. Run the main orchestrator with `./pacmaster.sh` for automated post-installation setup.

---

## 🎯 Key Features

### Hardware Support
- **NVIDIA Optimus** - Automatic GPU switching (Intel/NVIDIA)
- **Lenovo Legion Y520** - Full hardware support
- **Hybrid Graphics** - Power saving and performance modes

### Security
- **UFW Firewall** - Pre-configured DevOps rules
- **Fail2Ban** - SSH brute-force protection
- **GNOME Keyring** - Secure credential storage

### Development Tools
- **Docker & Docker Compose** - Containerization with NVIDIA runtime
- **Kubernetes** - kubectl, helm, k9s, kubectx
- **PostgreSQL** - Database server with remote access
- **VSCode & Windsurf** - AI-powered IDEs

### System Optimization
- **TLP & Intel Undervolt** - Power management
- **ZRAM** - Memory compression
- **BBR + CAKE** - Network optimization
- **Custom kernel tuning** - DevOps-optimized sysctl

---

---

## 🚀 Quick Start

### Option 1: Manual Installation
Follow the step-by-step guide below for a complete manual installation.

### Option 2: Automated Setup (Recommended)
Use the **PACUSER v2.0** suite for automated post-installation:

```bash
cd ../pacuser
cp app/config/pacuser.conf app/config/pacuser.conf.local
nano app/config/pacuser.conf.local  # Customize your settings
./pacmaster.sh
```

---

Before starting the installation, ensure you have:

- A bootable **Arch Linux USB drive**
- An active internet connection
- Backup of any important data from the device (installation will wipe all data on the disk)
- Access to UEFI/BIOS settings to boot from USB

---

## 📥 Installation Guide

### 1. Verify System Connection

### 2. Set Keyboard Layout

Set the keyboard layout to Italian (or your preferred layout):

```bash
loadkeys it
```

### 3. Update System Clock

Synchronize the system clock with NTP and set timezone:

```bash
timedatectl set-ntp true
timedatectl set-timezone Europe/Rome
```

### 4. Partitioning the Disk

Use **`cfdisk`** to create the following partitions on `/dev/nvme0n1`:

| Partition | Size | Type |
|-----------|------|------|
| EFI | 512MB | EFI System |
| Swap | 4GB | Linux swap |
| Root (`/`) | 50GB | Linux filesystem |
| Home (`/home`) | Remaining | Linux filesystem |

```bash
cfdisk /dev/nvme0n1
```

### 5. Format the Partitions

```bash
mkfs.fat -F32 /dev/nvme0n1p1  # EFI Partition
mkswap /dev/nvme0n1p2        # Swap Partition
swapon /dev/nvme0n1p2        # Activate swap
mkfs.ext4 /dev/nvme0n1p3      # Root Partition
mkfs.ext4 /dev/nvme0n1p4      # Home Partition
```

### 6. Mount the Partitions

```bash
mount /dev/nvme0n1p3 /mnt
mkdir /mnt/home
mount /dev/nvme0n1p4 /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
```

### 7. Install Base System

```bash
pacstrap /mnt base base-devel linux linux-firmware linux-headers intel-ucode nano git networkmanager
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash
```

### 8. Configure the System

#### Set Timezone
```bash
ln -sf /usr/share/zoneinfo/Europe/Rome /etc/localtime
hwclock --systohc
```

#### Configure Locale
```bash
nano /etc/locale.gen  # Uncomment it_IT.UTF-8 UTF-8
locale-gen
echo "LANG=it_IT.UTF-8" > /etc/locale.conf
```

#### Set Keyboard Layout
```bash
echo "KEYMAP=it" > /etc/vconsole.conf
```

#### Set Hostname
```bash
echo "archlegion" > /etc/hostname
```

#### Configure Hosts File
```bash
nano /etc/hosts
```

Add:
```
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlegion.localdomain    archlegion
```

#### Set Password for Root
```bash
passwd
```

#### Create a New User
```bash
useradd -m -G wheel,storage,power,audio,video,users -s /bin/bash username
passwd username
echo "username ALL=(ALL) ALL" | EDITOR=nano visudo
```

### 9. Install Bootloader (GRUB)

```bash
pacman -S grub efibootmgr dosfstools mtools --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

### 10. Network Configuration

```bash
systemctl enable NetworkManager
```

### 11. Finalizing the Installation

```bash
exit
umount -R /mnt
reboot
```

---

## 🔧 Post-Installation Steps

After rebooting, follow these guides for a complete setup:

1. **Desktop Environment** - See [`01-desktop.md`](01-desktop.md)
   - Install Xorg and KDE Plasma/XFCE
   - Configure NVIDIA drivers and Optimus Manager
   - Set up display manager

2. **System Utilities** - See [`02-utils.md`](02-utils.md)
   - Configure Zsh with Oh My Zsh
   - Install system optimizations
   - Set up power management (TLP, Intel Undervolt)
   - Configure firewall (UFW) and Fail2Ban

3. **Software Installation** - See [`03-software.md`](03-software.md)
   - Install essential applications
   - Set up Steam and VirtualBox
   - Configure Wine for Windows applications

4. **Automated Setup** - Use **PACUSER v2.0**
   ```bash
   cd ../pacuser
   ./pacmaster.sh
   ```

---

## 🔐 Security Configuration

### Firewall Setup

The system includes UFW firewall with DevOps-optimized rules:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

### Fail2Ban Setup

```bash
sudo pacman -S fail2ban --noconfirm
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### GNOME Keyring

For secure password storage, see [`software/gnome_keyring.md`](software/gnome_keyring.md).

---

## 🗄️ Database Setup

### PostgreSQL Installation

Complete PostgreSQL setup with remote access configuration:

- **Installation Guide**: [`software/postgress.md`](software/postgress.md)
- **Management Tips**: [`software/postgress_tips.md`](software/postgress_tips.md)

Quick setup:
```bash
sudo pacman -S postgresql
sudo -u postgres initdb --locale it_IT.UTF-8 -D /var/lib/postgres/data
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

---

## 📱 Additional Tools

### Virtual Webcam

Set up a virtual webcam using DroidCam:

```bash
sudo pacman -S v4l2loopback-dkms linux-headers
yay -S droidcam
```

See [`software/droid_cam.md`](software/droid_cam.md) for complete configuration.

### Cloud Storage

Mount Google Drive with Rclone:

```bash
sudo pacman -S rclone
rclone config
```

See [`software/rclone.md`](software/rclone.md) for detailed setup instructions.

---

## 🎮 Gaming & Performance

### GPU Switching

Switch between Intel (power saving) and NVIDIA (performance) GPUs:

```bash
optimus-manager --switch intel   # Power saving
optimus-manager --switch nvidia  # Performance
```

### Steam Setup

```bash
yay -S steam
```

### Power Management

- **TLP** - Advanced power management
- **Intel Undervolt** - CPU/GPU undervolting
- **ZRAM** - Memory compression

See [`02-utils.md`](02-utils.md) for complete optimization guide.

---

## 🛠️ Troubleshooting

### NVIDIA Issues

```bash
nvidia-smi                    # Check GPU status
optimus-manager --status      # Check current GPU mode
sudo reboot                   # Required after driver changes
```

### Docker Issues

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Network Issues

```bash
sudo ufw status numbered      # Check firewall
sudo systemctl status NetworkManager
```

---

## 📖 Additional Resources

- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Lenovo Legion Linux](https://github.com/johnfanv2/LenovoLegionLinux)
- [Main README](../README.md) - Repository overview

---

## 📄 License

MIT License - See [LICENSE](../LICENSE) for details.

---

## ⭐ Star the Project

If this guide helped you set up your Arch Linux workstation, consider giving it a star on GitHub!
