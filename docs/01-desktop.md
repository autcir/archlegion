# 🖥️ Arch Linux: Desktop Environment Setup for Lenovo Legion Y520

> Complete desktop installation with NVIDIA Optimus GPU switching

This guide walks you through installing **Xorg**, **KDE Plasma/XFCE**, **NVIDIA drivers**, and **Optimus Manager** on **Arch Linux** for the **Lenovo Legion Y520**. This setup allows you to switch between the integrated Intel GPU and the dedicated NVIDIA GPU, offering flexibility for power saving or performance as needed.

---

## 📋 Prerequisites

Before starting, ensure you have:
- A working installation of **Arch Linux**
- A stable internet connection
- Administrative (sudo) access

---

## 📚 Table of Contents

- [1. Install Xorg and Desktop Environment](#1-install-xorg-and-desktop-environment)
- [2. Install and Configure Display Manager](#2-install-and-configure-display-manager)
- [3. Install NVIDIA and Intel Drivers](#3-install-nvidia-and-intel-drivers)
- [4. Install Yay and Browser](#4-install-yay-and-browser)
- [5. Install and Configure Optimus Manager](#5-install-and-configure-optimus-manager)
- [6. Switch Between GPUs](#6-switch-between-gpus)
- [7. Troubleshooting](#7-troubleshooting)

---

## 1. Install Xorg and Desktop Environment

### Option A: KDE Plasma (Recommended)

```bash
sudo pacman -S xorg xorg-server --noconfirm
sudo pacman -S plasma plasma-desktop plasma-meta kde-applications --noconfirm
```

### Option B: XFCE (Lightweight)

```bash
sudo pacman -S xorg xorg-server --noconfirm
sudo pacman -S xfce4 xfce4-goodies --noconfirm
```

This installs the core components for running a graphical environment.

---

## 2. Install and Configure Display Manager

### For KDE Plasma (SDDM)

```bash
sudo pacman -S sddm sddm-kcm --noconfirm
sudo systemctl enable sddm
```

### For XFCE (LightDM)

```bash
sudo pacman -S lightdm lightdm-gtk-greeter --noconfirm
sudo systemctl enable lightdm
```

#### Configure LightDM (if using XFCE)

```bash
sudo nano /etc/lightdm/lightdm.conf
```

Find the line `greeter-session=` and set it to:
```
greeter-session=lightdm-gtk-greeter
```

---

## 3. Install NVIDIA and Intel Drivers

For optimal performance, you need both the **NVIDIA drivers** for the discrete GPU and **Intel drivers** for the integrated GPU. Run the following commands:

```bash
sudo pacman -S nvidia nvidia-utils nvidia-settings opencl-nvidia --noconfirm
sudo pacman -S mesa xf86-video-intel intel-media-driver --noconfirm
```

- `nvidia` installs the proprietary NVIDIA driver
- `mesa`, `xf86-video-intel`, and `intel-media-driver` install the necessary drivers for Intel GPUs

---

## 4. Install Yay and Browser

To easily install packages from the AUR (Arch User Repository), we'll install **yay**, an AUR helper:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
```

After installing yay, you can install additional software such as **Google Chrome** and **Optimus Manager**:

```bash
yay -S google-chrome optimus-manager
```

This will install Google Chrome as your web browser and **Optimus Manager**, which allows you to switch between the Intel and NVIDIA GPUs.

---

## 5. Install and Configure Optimus Manager

**Optimus Manager** allows you to switch between the Intel and NVIDIA GPUs. Enable and start the **Optimus Manager** service:

```bash
sudo systemctl enable optimus-manager.service
sudo systemctl start optimus-manager.service
```

After the installation, reboot your system for the changes to take effect:

```bash
sudo reboot
```

---

## 6. Switch Between GPUs

Once the system is back up, you can switch between the integrated Intel GPU and the dedicated NVIDIA GPU using the following commands:

### Switch to Intel GPU (Power Saving Mode)

```bash
optimus-manager --switch intel
```

### Switch to NVIDIA GPU (Performance Mode)

```bash
optimus-manager --switch nvidia
```

After switching, the system will prompt you to log out or restart to apply the changes.

---

## 7. Troubleshooting

### NVIDIA Not Detected

```bash
nvidia-smi
```

If this command fails, ensure you've rebooted after installing the drivers.

### Optimus Manager Not Working

```bash
optimus-manager --status
```

Check the current GPU mode and any error messages.

### Black Screen After NVIDIA Switch

1. Reboot into recovery mode
2. Switch back to Intel:
   ```bash
   optimus-manager --switch intel
   ```
3. Reboot normally

### Display Manager Not Starting

```bash
sudo systemctl status sddm  # or lightdm for XFCE
sudo journalctl -xe
```

Check the logs for error messages.

---

## 📖 Related Documentation

- [System Utilities](02-utils.md) - Zsh, optimizations, power management
- [Software Setup](03-software.md) - Applications, Steam, VirtualBox
- [README](README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../LICENSE) for details.
