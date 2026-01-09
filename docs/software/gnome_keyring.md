# 🔐 Arch Linux: Set up GNOME Keyring for Secure Storage

> Secure password and SSH key management on Arch Linux

This guide provides step-by-step instructions to configure **GNOME Keyring** on your **Arch Linux** system for secure management of passwords and SSH keys. The setup involves installing necessary packages, modifying PAM settings, and configuring environment variables.

---

## 📋 Prerequisites

Before proceeding, ensure that:
- You have **Arch Linux** installed
- You have administrative (sudo) access
- You are comfortable using a terminal and text editors

---

## 📚 Table of Contents

- [1. Install Required Packages](#1-install-required-packages)
- [2. Modify PAM Configuration](#2-modify-pam-configuration)
- [3. Configure User Environment](#3-configure-user-environment)
- [4. Verify the Setup](#4-verify-the-setup)
- [5. Restart GNOME Keyring Daemon](#5-restart-gnome-keyring-daemon)
- [6. Install Seahorse for Keyring Management](#6-install-seahorse-for-keyring-management)
- [7. Troubleshooting](#7-troubleshooting)

---

## 1. Install Required Packages

First, install the necessary packages for **GNOME Keyring** and **libsecret** to securely store passwords:

```bash
sudo pacman -S gnome-keyring libsecret
```

---

## 2. Modify PAM Configuration

Next, modify the **PAM** configuration file to ensure that **GNOME Keyring** is loaded on login. Open the **login** file in your preferred text editor (using **nano** here):

```bash
sudo nano /etc/pam.d/login
```

Scroll to the end of the file and add the following two lines:

```bash
auth optional pam_gnome_keyring.so
session optional pam_gnome_keyring.so auto_start
```

Save the file by pressing `CTRL+O`, then press `ENTER`, and finally exit by pressing `CTRL+X`.

---

## 3. Configure User Environment

Now, we need to configure the user environment. Open (or create) the `.xprofile` file in your home directory:

```bash
nano ~/.xprofile
```

Add the following lines to the file:

```bash
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
```

This will start the **GNOME Keyring** daemon for managing your keys and environment.

---

## 4. Verify the Setup

To verify that everything is working correctly, check the environment variables to ensure the keyring daemon is running:

```bash
echo $GNOME_KEYRING_CONTROL
echo $SSH_AUTH_SOCK
```

Both should return paths under `/run/user/1000/`, confirming that **GNOME Keyring** is active.

---

## 5. Restart GNOME Keyring Daemon

If you need to restart the **GNOME Keyring Daemon**, you can kill the existing process and restart it:

```bash
killall gnome-keyring-daemon
gnome-keyring-daemon --start --components=pkcs11,secrets,ssh
```

This will restart the daemon and ensure that **GNOME Keyring** is running properly.

---

## 6. Install Seahorse for Keyring Management

To manage your keyring and stored passwords, you can install **Seahorse**, a GUI for GNOME Keyring:

```bash
sudo pacman -S seahorse
```

Once installed, you can launch **Seahorse** from your application menu and easily manage your passwords and SSH keys.

---

## 7. Troubleshooting

### Keyring Not Unlocking Automatically

If the keyring doesn't unlock on login, verify PAM configuration:

```bash
cat /etc/pam.d/login | grep gnome-keyring
```

### SSH Keys Not Added

Check if SSH_AUTH_SOCK is set:

```bash
echo $SSH_AUTH_SOCK
```

If empty, manually start the daemon:

```bash
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK
```

### Seahorse Not Showing Keys

Restart the keyring daemon:

```bash
killall gnome-keyring-daemon
gnome-keyring-daemon --start --components=pkcs11,secrets,ssh
```

---

## 📖 Related Documentation

- [PostgreSQL Setup](postgress.md) - Database installation
- [Virtual Webcam](droid_cam.md) - DroidCam setup
- [README](../README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../../LICENSE) for details.
