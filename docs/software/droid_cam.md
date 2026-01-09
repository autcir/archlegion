# 📹 Virtual Webcam Setup on Arch Linux: v4l2loopback & DroidCam

> Use your Android phone as a webcam on Arch Linux

This guide provides instructions on how to set up a virtual webcam using `v4l2loopback` and `DroidCam` on Arch Linux. The virtual webcam can be used for various applications like video conferencing, streaming, or testing webcam software without requiring a physical webcam.

---

## 📋 Prerequisites

- An Arch Linux system
- An internet connection
- Root (sudo) privileges
- Android phone with DroidCam app installed

---

## 📚 Table of Contents

- [1. Install Required Packages](#1-install-required-packages)
- [2. Load the v4l2loopback Kernel Module](#2-load-the-v4l2loopback-kernel-module)
- [3. Configure Automatic Module Loading](#3-configure-automatic-module-loading)
- [4. Set Default Parameters](#4-set-default-parameters)
- [5. Reload the Modules](#5-reload-the-modules)
- [6. Auto-install Kernel Modules](#6-auto-install-kernel-modules)
- [7. Connect DroidCam](#7-connect-droidcam)

---

## 1. Install Required Packages

First, you need to install the necessary packages for the virtual webcam setup.

Run the following commands to install the required packages:

```bash
sudo pacman -S v4l2loopback-dkms linux-headers
yay -S droidcam
```

- `v4l2loopback-dkms`: The kernel module that creates virtual video devices.
- `linux-headers`: Required to build kernel modules.
- `droidcam`: A popular Android app that turns your phone into a webcam for your computer.

---

## 2. Load the v4l2loopback Kernel Module

After installing the required packages, you need to load the `v4l2loopback` module to create a virtual webcam device.

Run the following command to load the module:

```bash
sudo modprobe v4l2loopback devices=1 exclusive_caps=1
```

- `devices=1`: Creates a single virtual webcam device.
- `exclusive_caps=1`: Ensures exclusive capture for the virtual device.

To verify that the virtual webcam device has been created, check the `/dev/video*` devices:

```bash
ls /dev/video*
```

---

## 3. Configure Automatic Module Loading

To ensure that the `v4l2loopback` module loads automatically at boot, create a configuration file to load the module at startup.

Run the following command to edit the configuration:

```bash
sudo nano /etc/modules-load.d/v4l2loopback.conf
```

Add the following line to the file:

```
v4l2loopback
```

Save the file and exit (`CTRL + O`, `ENTER`, `CTRL + X`).

---

## 4. Set Default Parameters

Now, you can set the default parameters for `v4l2loopback`. This step ensures the module is loaded with the desired settings every time the system boots.

Open the `v4l2loopback.conf` file for editing:

```bash
sudo nano /etc/modprobe.d/v4l2loopback.conf
```

Add the following line to the file:

```
options v4l2loopback devices=1 exclusive_caps=1
```

Save the file and exit (`CTRL + O`, `ENTER`, `CTRL + X`).

---

## 5. Reload the Modules

To apply the changes and load the module with the new configuration, you can unload and reload the `v4l2loopback` module as follows:

```bash
sudo modprobe -r v4l2loopback
sudo modprobe v4l2loopback devices=1 exclusive_caps=1
```

This will reload the module with the specified parameters.

---

## 6. Auto-install Kernel Modules

To ensure that the kernel modules are automatically installed and up to date, run the following command:

```bash
sudo dkms autoinstall
```

This command will ensure that any necessary kernel module updates are installed automatically when you update your kernel.

---

## 7. Connect DroidCam

### Install DroidCam App on Android

1. Download **DroidCam** from Google Play Store
2. Connect your phone and computer to the same network

### Start DroidCam Server

```bash
droidcam
```

### Connect from Android App

1. Open DroidCam app on your phone
2. Enter your computer's IP address
3. Tap "Connect"

### Verify Connection

```bash
ls /dev/video*
```

You should see the virtual webcam device listed.

---

## 🔧 Troubleshooting

### Module Not Loading

```bash
sudo modprobe v4l2loopback devices=1 exclusive_caps=1
```

### No Video Device Found

```bash
sudo dkms autoinstall
sudo reboot
```

### Connection Issues

- Ensure both devices are on the same network
- Check firewall settings
- Try USB connection instead of Wi-Fi

---

## 📖 Related Documentation

- [GNOME Keyring](gnome_keyring.md) - Secure credential storage
- [README](../README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../../LICENSE) for details.
