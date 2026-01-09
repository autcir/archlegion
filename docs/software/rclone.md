# ☁️ Rclone Configuration: Google Drive Mount on Arch Linux

> Mount Google Drive as a local filesystem on Arch Linux

This guide provides complete instructions for configuring `rclone` with Google Drive and mounting it as a local filesystem on Arch Linux. Includes setup for manual mounting, scripts, and automatic systemd service.

---

## 📋 Prerequisites

- Arch Linux system
- Google account
- Internet connection
- Sudo privileges

---

## 📚 Table of Contents

- [1. Install rclone](#1-install-rclone)
- [2. Configure Remote (Google Drive)](#2-configure-remote-google-drive)
- [3. Verify Configuration](#3-verify-configuration)
- [4. Manual Mount](#4-manual-mount)
- [5. Create Mount Script](#5-create-mount-script)
- [6. Configure Systemd Service](#6-configure-systemd-service)
- [7. Troubleshooting](#7-troubleshooting)

---

## 1. Install rclone

```bash
sudo pacman -S rclone
```

---

## 2. Configure Remote (Google Drive)

### Start Configuration

```bash
rclone config
```

### Configuration Steps

1. Type `n` for **new remote**
2. Enter a name (e.g., `SOLISO`)
3. Select **Google Drive** (type the corresponding number)
4. For most options, press **Enter** to accept defaults:
   - **Client ID**: Leave empty
   - **Client Secret**: Leave empty
   - **Scope**: Select "full access" (`drive`)
   - **Root Folder ID**: Leave empty
   - **Service Account**: Leave empty
5. Type `y` for advanced configuration (optional)
6. Type `y` to use auto config
7. A browser window will open - authorize rclone
8. Copy the authorization code and paste it in the terminal
9. Type `y` to confirm and test the configuration
10. Type `q` to quit

---

## 3. Verify Configuration

List the contents of your Google Drive:

```bash
rclone ls SOLISO:
```

If configured correctly, you'll see your files and folders.

---

## 4. Manual Mount

Mount the remote to a local directory:

```bash
mkdir -p ~/Desktop/Project/Soliso/
rclone mount SOLISO: ~/Desktop/Project/Soliso/ --vfs-cache-mode writes
```

The `--vfs-cache-mode writes` option improves file handling.

---

## 5. Create Mount Script

### Create Script File

```bash
nano ~/mount_soliso.sh
```

### Add Script Content

```bash
#!/bin/bash
rclone mount SOLISO: ~/Desktop/Project/Soliso/ --vfs-cache-mode writes
```

### Make Executable

```bash
chmod +x ~/mount_soliso.sh
```

### Run Script

```bash
~/mount_soliso.sh
```

---

## 6. Configure Systemd Service

### Create Service File

```bash
sudo nano /etc/systemd/system/rclone-mount.service
```

### Add Service Configuration

```ini
[Unit]
Description=Rclone Mount SOLISO
After=network-online.target

[Service]
Type=simple
User=YOUR_USERNAME
ExecStart=/usr/bin/rclone mount SOLISO: /home/YOUR_USERNAME/Desktop/Project/Soliso/ --vfs-cache-mode writes
ExecStop=/bin/fusermount -u /home/YOUR_USERNAME/Desktop/Project/Soliso/
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

**Note**: Replace `YOUR_USERNAME` with your actual username.

### Enable and Start Service

```bash
sudo systemctl daemon-reload
sudo systemctl enable rclone-mount.service
sudo systemctl start rclone-mount.service
```

### Check Service Status

```bash
sudo systemctl status rclone-mount.service
```

---

## 7. Troubleshooting

### Mount Failed: "directory not found"

Ensure the mount directory exists:

```bash
mkdir -p ~/Desktop/Project/Soliso/
```

### Permission Denied

Check file permissions:

```bash
ls -la ~/Desktop/Project/
```

Ensure you own the directory:

```bash
sudo chown -R $USER:$USER ~/Desktop/Project/Soliso/
```

### Service Not Starting

Check service logs:

```bash
sudo journalctl -u rclone-mount.service -n 50
```

### Connection Issues

- Ensure internet connection is active
- Verify rclone configuration: `rclone config show SOLISO:`
- Test remote: `rclone ls SOLISO:`

### Unmount Manually

```bash
fusermount -u ~/Desktop/Project/Soliso/
```

---

## 📚 Additional rclone Commands

### Sync Local to Remote

```bash
rclone sync ~/local-folder SOLISO:remote-folder
```

### Copy Files

```bash
rclone copy ~/local-file SOLISO:remote-folder/
```

### Check Remote Size

```bash
rclone size SOLISO:
```

### List Remotes

```bash
rclone listremotes
```

---

## 📖 Related Documentation

- [PostgreSQL Setup](postgress.md) - Database installation
- [GNOME Keyring](gnome_keyring.md) - Secure credential storage
- [README](../README.md) - Main installation guide

---

## 📄 License

MIT License - See [LICENSE](../../LICENSE) for details.