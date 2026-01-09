# 🖥️ Arch Linux DevOps Workstation - Complete Setup

> **Automated Arch Linux installation and configuration for DevOps, Cloud Engineering, and Development**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![DevOps](https://img.shields.io/badge/DevOps-Ready-blue?style=for-the-badge)](https://www.devops.com/)
[![Lenovo Legion](https://img.shields.io/badge/Lenovo_Legion-Y520-red?style=for-the-badge)](https://www.lenovo.com/it/it/laptops/legion-series/legion-y-series/legion-y520/)

This repository provides a complete, automated solution for installing and configuring **Arch Linux** on the **Lenovo Legion Y520** laptop, optimized for professional DevOps and development work. The setup includes GPU switching (NVIDIA Optimus), security hardening, containerization tools, and comprehensive documentation.

---

## 🎯 What's Included

### 🚀 Installation Methods

| Method | Description | Time Required |
|--------|-------------|---------------|
| **Manual** | Step-by-step installation following guides | 2-3 hours |
| **Archinstall** | Semi-automated installation with config files | 1-2 hours |
| **PACUSER Suite** | Fully automated post-installation setup | 30-45 min |

### 💻 Hardware Support

- ✅ **NVIDIA Optimus** - Automatic GPU switching (Intel/NVIDIA)
- ✅ **Lenovo Legion Y520** - Full hardware support
- ✅ **Hybrid Graphics** - Power saving and performance modes
- ✅ **Legacy GPU Support** - Pascal, Maxwell architectures

### 🔒 Security Features

- ✅ **UFW Firewall** - Pre-configured DevOps rules
- ✅ **Fail2Ban** - SSH brute-force protection
- ✅ **GNOME Keyring** - Secure credential storage
- ✅ **System Hardening** - DevOps-optimized sysctl

### 🛠️ Development Tools

- ✅ **Docker & Docker Compose** - With NVIDIA runtime
- ✅ **Kubernetes** - kubectl, helm, k9s, kubectx
- ✅ **PostgreSQL** - Database with remote access
- ✅ **VSCode & Windsurf** - AI-powered IDEs
- ✅ **Node.js + pnpm**, **Python + UV**

### ⚡ System Optimizations

- ✅ **TLP & Intel Undervolt** - Power management
- ✅ **ZRAM** - Memory compression
- ✅ **BBR + CAKE** - Network optimization
- ✅ **Custom kernel tuning** - DevOps-optimized

---

## 📁 Repository Structure

```
archlegion/
├── README.md                    # This file
├── pacmaster.sh                 # Main orchestrator wrapper
│
├── archinstall/                 # 🏗️ Archinstall configurations
│   ├── README.md                # Archinstall usage guide
│   ├── user_configuration.json  # System config
│   ├── user_credentials.json    # User credentials (template)
│   └── partition_preset.json    # Disk partitioning preset
│
├── config/                      # ⚙️ Configuration files
│   ├── pacuser.conf             # Main configuration
│   ├── starship.toml            # Starship prompt config
│   └── dotfiles/                # Shell and app configs
│
├── scripts/                     # 📜 Installation scripts
│   ├── pacmaster.sh             # Real orchestrator
│   ├── 00_chroot_setup.sh       # Base system setup
│   ├── 01_desktop_install.sh    # Desktop & drivers
│   ├── 02_yay_optimus.sh        # AUR & Optimus Manager
│   ├── 03_system_tuning.sh      # Tuning & security
│   ├── 04_software_setup.sh     # DevOps software
│   ├── 05_extras_setup.sh       # Shell & extras
│   ├── 99_safe_reboot_check.sh  # Pre-reboot verification
│   └── lib/                     # Shared libraries
│
└── docs/                        # 📚 Documentation
    ├── README.md                # Main installation guide
    ├── 01-desktop.md            # Desktop environment setup
    ├── 02-utils.md              # System utilities & optimizations
    ├── 03-software.md           # Software installation
    └── software/                # Software-specific guides
        ├── postgress.md         # PostgreSQL installation
        ├── postgress_tips.md    # PostgreSQL management
        ├── gnome_keyring.md     # GNOME Keyring setup
        ├── droid_cam.md         # Virtual webcam
        └── rclone.md            # Google Drive mount
```

---

## 🚀 Quick Start

### Option 1: Manual Installation (Recommended for Learning)

Follow the comprehensive installation guide:

```bash
# 1. Read the main installation guide
cat docs/README.md

# 2. Follow the step-by-step installation process
# - Base Arch Linux installation
# - Desktop environment setup
# - System utilities and optimizations
# - Software installation
```

### Option 2: Archinstall (Semi-Automated)

Use the pre-configured archinstall files:

```bash
# 1. Boot from Arch Linux ISO
# 2. Connect to internet
# 3. Copy archinstall configuration files
cp archinstall/*.json /root/archinstall/

# 4. Edit credentials
nano /root/archinstall/user_credentials.json

# 5. Run archinstall
archinstall --config /root/archinstall/user_configuration.json \
            --creds /root/archinstall/user_credentials.json

# 3. After first boot, run PACUSER
./pacmaster.sh
```

See [archinstall/README.md](archinstall/README.md) for detailed instructions.

### Option 3: PACUSER Suite (Fully Automated)

After base Arch Linux installation, run the automated suite:

```bash
# 1. Clone this repository
git clone https://github.com/ciroautuori/archlegion.git
cd archlegion

# 2. Configure your settings
cp config/pacuser.conf config/pacuser.conf.local
nano config/pacuser.conf.local

# 3. Run the orchestrator
./pacmaster.sh
```

The PACUSER suite automates all post-installation steps including desktop setup, system tuning, security configuration, and software installation.

---

## 📚 Documentation

### Installation Guides

| Document | Description |
|----------|-------------|
| [Main Installation Guide](docs/README.md) | Complete Arch Linux installation |
| [Desktop Setup](docs/01-desktop.md) | KDE/XFCE, NVIDIA, Optimus Manager |
| [System Utilities](docs/02-utils.md) | Zsh, optimizations, power management |
| [Software Setup](docs/03-software.md) | Applications, Steam, VirtualBox |

### Software Configuration

| Document | Description |
|----------|-------------|
| [PostgreSQL Installation](docs/software/postgress.md) | Database setup with remote access |
| [PostgreSQL Management](docs/software/postgress_tips.md) | Users, databases, and roles |
| [GNOME Keyring](docs/software/gnome_keyring.md) | Secure credential storage |
| [Virtual Webcam](docs/software/droid_cam.md) | DroidCam setup |
| [Rclone](docs/software/rclone.md) | Google Drive mount |

### Configuration

| File | Description |
|------|-------------|
| [pacuser.conf](config/pacuser.conf) | Main configuration file |
| [starship.toml](config/starship.toml) | Starship prompt theme |
| [archinstall config](archinstall/) | Archinstall configurations |

---

## 🎨 Features by Category

### 🖥️ Desktop Environment

- **KDE Plasma** - Modern, feature-rich desktop
- **XFCE** - Lightweight alternative
- **NVIDIA Drivers** - Proprietary with Optimus support
- **PipeWire Audio** - Modern audio stack
- **Display Manager** - SDDM (KDE) or LightDM (XFCE)

### 🔐 Security

- **UFW Firewall** - Pre-configured DevOps rules
- **Fail2Ban** - SSH brute-force protection
- **GNOME Keyring** - Secure password storage
- **System Hardening** - DevOps-optimized sysctl

### ☁️ Cloud & Containerization

- **Docker** - With NVIDIA runtime support
- **Docker Compose** - Multi-container applications
- **Kubernetes Tools** - kubectl, helm, k9s
- **Google Cloud SDK** - GCP management

### 💻 Development

- **VSCode** - Visual Studio Code
- **Windsurf** - AI-powered IDE
- **Git** - Version control with aliases
- **Node.js + pnpm** - JavaScript development
- **Python + UV** - Python development

### ⚡ Performance

- **TLP** - Advanced power management
- **Intel Undervolt** - CPU/GPU undervolting
- **ZRAM** - Memory compression
- **BBR + CAKE** - Network optimization

### 🎮 Gaming

- **Steam** - Gaming platform
- **Proton** - Windows game compatibility
- **NVIDIA Optimus** - GPU switching
- **GameMode** - Performance optimization

---

## 🛠️ Configuration

### Main Configuration File

Edit `config/pacuser.conf` to customize your installation:

```bash
# System settings
PACUSER_HOSTNAME="archlinux"
PACUSER_USERNAME="yourname"
PACUSER_TIMEZONE="Europe/Rome"

# Docker settings
PACUSER_DOCKER_ROOT="/var/lib/docker"
PACUSER_DOCKER_NVIDIA="1"

# Graphics settings
PACUSER_OPTIMUS_MODE="hybrid"
PACUSER_ENABLE_OPTIMUS_MANAGER="0"

# Power management
PACUSER_ENABLE_UNDERVOLT="1"
PACUSER_UNDERVOLT_CPU="-80"

# Security
PACUSER_ENABLE_UFW="1"
PACUSER_ENABLE_FAIL2BAN="1"

# IDEs
PACUSER_INSTALL_IDES="vscode windsurf"
```

See [Configuration Guide](config/pacuser.conf) for all available options.

---

## 🧪 Testing

### Verify Installation

After installation, run these checks:

```bash
# Check GPU
nvidia-smi
optimus-manager --status

# Check Docker
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Check PostgreSQL
sudo -u postgres psql -c "SELECT version();"

# Check Firewall
sudo ufw status

# Check Services
systemctl status tlp
systemctl status docker
```

### Run Tests

```bash
# Run PACUSER test suite
cd scripts/tests
./run_tests.sh
```

---

## 🔧 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| NVIDIA not detected | Reboot after driver installation |
| Optimus Manager not working | Check `optimus-manager --status` |
| Docker requires sudo | Add user to docker group |
| Firewall blocking connections | Check `sudo ufw status` |
| PostgreSQL not starting | Check `sudo journalctl -u postgresql` |

For detailed troubleshooting, see the [Troubleshooting Guide](docs/README.md#troubleshooting).

---

## 📖 Resources

- [Arch Linux Wiki](https://wiki.archlinux.org/)
- [Lenovo Legion Linux](https://github.com/johnfanv2/LenovoLegionLinux)
- [Archinstall Documentation](https://github.com/archlinux/archinstall)
- [NVIDIA Arch Wiki](https://wiki.archlinux.org/title/NVIDIA)

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ Star History

If this project helped you set up your Arch Linux workstation, consider giving it a star!

---

## 📞 Support

For issues and questions:

- Open an issue on GitHub
- Check the [documentation](docs/)
- Review [troubleshooting guides](docs/README.md#troubleshooting)

---

**Made with ❤️ for the Arch Linux community**
