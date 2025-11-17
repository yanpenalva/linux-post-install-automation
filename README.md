# Linux Post-Install Automation Script

This repository contains **my personal Linux post-installation automation script**, built to give me a **plug-and-play development environment** whenever I reinstall a system or switch Linux distributions.  
The script installs everything I use daily, applies system fixes, configures my shell, and sets up a consistent workstation across different distros.

It is **opinionated**, **personal**, and **continuously evolving** as my workflow changes.

---

## Supported & Tested Distributions

The script contains logic for the following distribution families:

| Distribution Family | Package Manager | Status |
|---------------------|-----------------|--------|
| Ubuntu / Debian / Pop!_OS / Linux Mint | `apt` | **Tested** (Pop!_OS, Linux Mint) |
| Fedora | `dnf` | Supported (not tested) |
| Arch / Manjaro | `pacman` | **Tested** (Manjaro) |

### Disclaimer
The script *should* work on all supported distros, but **I have only personally tested** on:
- **Pop!_OS**
- **Linux Mint**
- **Manjaro**

---

## Purpose

I use this script to automate my full environment setup when changing distributions.  
My goal is a **complete, reproducible, and consistent development environment** in minutes, without having to reconfigure everything manually.

This is not a universal template — it includes exactly the tools **I** use daily.

---

## What the Script Installs

Below is a full breakdown of **every component** installed depending on the chosen profile.

---

# 1. SYSTEM PACKAGES (Minimal, Dev, Full)

Installed on **all profiles**:

### `zsh`
Default shell, to be combined with Oh-My-Zsh.

### `git`
Version control and Git global config helper.

### `curl`
HTTP client used for downloading scripts (NVM, Docker, Oh-My-Zsh, etc).

### `htop`
Process monitor.

### `vim`
Text editor.

### `qbittorrent`
Torrent client.

### `btop`
High-performance resource monitor.

### `bat`
Improved `cat` with syntax highlighting.

---

# 2. DEVELOPER PACKAGES (Dev, Full)

Installed when profile **dev** or **full** is selected:

### `python3`
System-wide Python runtime.

### `php`
System-wide PHP runtime.

### `filezilla`
FTP/SFTP GUI client.

---

# 3. DEVELOPMENT ENVIRONMENT (Dev, Full)

### Zsh + Oh-My-Zsh
- Installs Zsh  
- Installs Oh-My-Zsh  
- Sets Zsh as the default shell  

### Git Global Setup
Prompts for:
- `user.name`
- `user.email`

Automatically sets:
- default branch: `main`  
- color output  
- global configuration  

### NVM
Node Version Manager installed from the official script.

### Docker
Installed via:
- Official Docker convenience script (`apt`/`dnf`)
- Direct packages for Arch (`pacman`)

Also:
- Enables Docker service on Arch
- Adds the user to the `docker` group

### Visual Studio Code
Installed directly from the official Microsoft binaries:
- `.deb`
- `.rpm`
- pacman repo package

---

# 4. FLATPAK ENVIRONMENT (Full Only)

The **full** profile ensures Flatpak exists and adds Flathub if missing.

Then the script installs:

## Browsers
- **Google Chrome** (`com.google.Chrome`)
- **Microsoft Edge** (`com.microsoft.Edge`)

## Applications
- **VLC** (`org.videolan.VLC`)
- **Telegram** (`org.telegram.desktop`)
- **Discord** (`com.discordapp.Discord`)
- **Stremio** (`com.stremio.Stremio`)
- **LibreOffice** (`org.libreoffice.LibreOffice`)
- **Spotify** (`com.spotify.Client`)

## Termius (APT-only)
SSH client installed via `.deb`.

---

# 5. SYSTEM MAINTENANCE

### APT Full Repair
Runs:
- `dpkg --configure -a`
- `apt --fix-broken install`
- `apt full-upgrade`
- `apt autoremove`

### Snap Removal (APT-only)
Completely removes:
- snap packages  
- snapd  
- snap directories  
And marks snapd as held to prevent reinstallation.

---

# 6. Profiles Summary

| Profile | What is Installed |
|---------|--------------------|
| **Minimal** | System packages + Zsh + Oh-My-Zsh |
| **Dev** | Minimal + (Python, PHP, Filezilla, VSCode, Docker, NVM, Git configuration) |
| **Full** | Dev + Flatpak environment + Browsers + Apps + Termius |

---

## Usage

```bash
git clone https://github.com/yourname/linux-post-install-automation.git
cd linux-post-install-automation
chmod +x post-install.sh
./post-install.sh
```

Start installation:

```
start
```

Select a profile:

```
1 = minimal
2 = dev
3 = full
```

---

## Requirements
- Supported Linux distribution  
- Internet access  
- sudo privileges  

---

## Final Notes

- This script is **built for my own workflow** and contains my daily-use software.  
- It evolves frequently as I adjust my environment.  
- It is safe to run multiple times (idempotent logic checks for existing installations).  
- You may fork it, customize it, or use it as inspiration for your own setup.

---
