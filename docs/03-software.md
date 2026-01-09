# 💻 Arch Linux - Post-Installation Software Setup for Lenovo Legion Y520

> Essential applications, development tools, and productivity software

This guide will help you install essential applications, set up Wine, configure VirtualBox, and apply some customizations such as a cursor and theme for your Arch Linux installation.

---

## 📚 Table of Contents

- [1. Install Steam](#1-install-steam)
- [2. Install Additional Applications](#2-install-additional-applications)
- [3. VirtualBox Setup](#3-virtualbox-setup)
- [4. Wine Setup](#4-wine-setup)
- [5. Cursor Installation](#5-cursor-installation)
- [6. LMStudio Setup](#6-lmstudio-setup)
- [7. Apply WhiteSur Theme](#7-apply-whitesur-theme)
- [8. Final Backup](#8-final-backup)
- [9. Troubleshooting](#9-troubleshooting)

---

## 1. Install Steam

To install Steam with NVIDIA drivers support, use the following command:

```bash
yay -S steam (scelta-nvidia)
```

---

## 2. Install Additional Applications

Here are some additional applications you can install. This includes popular programs like **LibreOffice**, **Discord**, **VirtualBox**, and **Spotify**.

```bash
sudo pacman -S --noconfirm libreoffice-fresh discord virtualbox virtualbox-host-modules-arch obsidian
yay -S --noconfirm anydesk whatsdesk-bin telegram-desktop-bin spotify visual-studio-code-bin xfce4-docklike-plugin icloud-notes-git optimus-manager-qt inkscape gimp
```

---

## 3. VirtualBox Setup

To set up VirtualBox, add your user to the `vboxusers` group and load the necessary modules:

```bash
sudo usermod -aG vboxusers $USER
sudo modprobe vboxdrv
sudo modprobe vboxnetflt
sudo modprobe vboxnetadp
```

Enable and start the VirtualBox web service:

```bash
sudo systemctl enable vboxweb.service
sudo systemctl start vboxweb.service
```

---

## 4. Wine Setup

To install **Wine** and configure it for running Windows applications, first update the system:

```bash
sudo pacman -Syyu
```

Install Wine and its dependencies:

```bash
sudo pacman -S wine winetricks wine-mono wine-gecko
```

Run `winecfg` to set up Wine:

```bash
winecfg
```

---

## 5. Cursor Installation

To install a custom cursor, you can download the **Cursor** AppImage from the official website:

[Download Cursor](https://www.cursor.com/)

Make the AppImage executable and run it:

```bash
chmod +x cursor-*.AppImage
./cursor-*.AppImage
```

Move the AppImage to `/opt` and create a desktop entry to launch it easily:

```bash
sudo mv cursor-*.AppImage /opt/cursor.appimage
sudo nano /usr/share/applications/cursor.desktop
```

Add the following content to create a launcher:

```bash
[Desktop Entry]
Name=Cursor
Exec=/opt/cursor.appimage
Icon=/opt/cursor.png
Type=Application
Categories=Development;
```

---

## 6. LMStudio Setup

To install **LMStudio**, download the AppImage from the official website:

[Download LMStudio](https://installers.lmstudio.ai/linux/x64/0.3.6-8/LM-Studio-0.3.6-8-x64.AppImage)

Make it executable and run it:

```bash
chmod +x LM-Studio-0.3.6-8-x64.AppImage
./LM-Studio-0.3.6-8-x64.AppImage
```

Move the AppImage to `/opt` and create a desktop entry:

```bash
sudo mv LM-Studio-0.3.6-8-x64.AppImage /opt/lmstudio.appimage
sudo nano /usr/share/applications/lmstudio.desktop
```

Add the following content to create a launcher:

```bash
[Desktop Entry]
Name=LMStudio
Exec=/opt/lmstudio.appimage
Icon=/opt/lmstudio.png
Type=Application
Categories=Development;
```

---

## 7. Apply WhiteSur Theme

To install the **WhiteSur** GTK theme, run the following commands:

```bash
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme
./install.sh -o solid -c dark
./tweaks.sh --firefox  # (if you use Firefox)
cd ..
rm -rf WhiteSur-gtk-theme
sudo reboot
```

---

## 8. Final Backup

Once everything is installed and configured, create a backup of the system using **Timeshift**:

```bash
sudo timeshift --create --comments "full"
```

---

## 9. Troubleshooting

### Steam Not Launching

```bash
steam --reset
```

Or reinstall with NVIDIA support:
```bash
yay -S steam
```

### VirtualBox Kernel Modules Not Loading

```bash
sudo modprobe vboxdrv vboxnetflt vboxnetadp
```

Ensure your user is in the vboxusers group:
```bash
sudo usermod -aG vboxusers $USER
```

### Wine Applications Not Starting

```bash
winecfg
```

Check if Wine is configured correctly and try running in compatibility mode.

### AppImage Not Executing

```bash
chmod +x filename.AppImage
./filename.AppImage
```

If still not working, check for missing dependencies:
```bash
ldd filename.AppImage | grep not found
```

### Theme Not Applying

```bash
kwriteconfig5 --file kdeglobals --group KDE --keyLookAndFeelTheme WhiteSur
```

Or use system settings to apply the theme manually.

---

## 📖 Related Documentation

- [Desktop Setup](01-desktop.md) - KDE/XFCE, NVIDIA, Optimus
- [System Utilities](02-utils.md) - Zsh, optimizations, power management
- [README](README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../LICENSE) for details.
