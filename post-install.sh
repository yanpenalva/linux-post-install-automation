#!/usr/bin/env bash
set -e

: '
This script automates Linux post-installation.
It detects the distro, installs system and development tools, configures Zsh + Oh-My-Zsh, Git, NVM, Docker, VS Code, Flatpak, and optional applications.
It also fixes APT issues, removes Snap if present, and ensures idempotent installation by checking for existing packages.
Profiles available: minimal, dev, full.
'

clear
echo -e "\e[1;36m
   ,_,  
  (0,0) 
  { \" } 
  -\"-\"-
\e[0m"
echo -e "\e[1;35mLinux Post Install Automation\e[0m"
echo -e "\e[1;34m-------------------------------------\e[0m"
echo -e "\e[1;37mType \e[1;32mstart\e[1;37m to begin or CTRL+C to abort.\e[0m"
echo
read -rp "> " CONFIRM
[[ "$CONFIRM" != "start" ]] && echo -e "\e[1;31mCancelled.\e[0m" && exit 1
clear

RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
MAGENTA="\e[1;35m"
CYAN="\e[1;36m"
RESET="\e[0m"

msg()  { echo -e "${BLUE}[INFO]${RESET} $1"; }
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1"; }

progress() {
    echo -ne "[ "
    for _ in {1..25}; do echo -ne "█"; sleep 0.02; done
    echo " ]"
}

detect_pkg_manager() {
    . /etc/os-release
    case "$ID" in
        ubuntu|debian|pop|linuxmint) echo "apt" ;;
        fedora) echo "dnf" ;;
        arch|manjaro) echo "pacman" ;;
        *) echo "unknown" ;;
    esac
}

PKG=$(detect_pkg_manager)
[[ "$PKG" == "unknown" ]] && err "Unsupported distro" && exit 1

bin_exists() { command -v "$1" >/dev/null 2>&1; }
pkg_apt_installed() { dpkg -s "$1" >/dev/null 2>&1; }
flatpak_installed() { flatpak list --app | awk '{print $1}' | grep -qx "$1"; }

install_pkg() {
    local pkg="$1"
    case "$PKG" in
        apt)
            pkg_apt_installed "$pkg" && ok "$pkg already installed" && return
            msg "Installing $pkg (apt)…"; progress
            sudo apt install -y "$pkg"
        ;;
        dnf)
            bin_exists "$pkg" && ok "$pkg already installed" && return
            msg "Installing $pkg (dnf)…"; progress
            sudo dnf install -y "$pkg"
        ;;
        pacman)
            pacman -Qi "$pkg" &>/dev/null && ok "$pkg already installed" && return
            msg "Installing $pkg (pacman)…"; progress
            sudo pacman -Sy --noconfirm "$pkg"
        ;;
    esac
}

apt_full_fix() {
    [[ "$PKG" != "apt" ]] && return
    msg "Running dpkg/apt repair…"; progress
    sudo dpkg --configure -a || true
    sudo apt --fix-broken install -y || true
    sudo apt install -f -y || true
    sudo apt update || true
    sudo apt full-upgrade -y || true
    sudo apt autoremove -y || true
}

apt_full_fix

remove_snap() {
    [[ "$PKG" != "apt" ]] && return
    msg "Removing Snap…"; progress
    sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
    if bin_exists snap; then
        for pkg in $(snap list | awk 'NR>1 {print $1}'); do sudo snap remove "$pkg" --purge || true; done
    fi
    sudo apt purge -y snapd || true
    sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
    sudo apt-mark hold snapd
    ok "Snap removed"
}

remove_snap

ensure_flatpak() {
    if ! bin_exists flatpak; then
        msg "Installing flatpak…"; progress
        install_pkg flatpak
    fi
    flatpak remotes | grep -q flathub || flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    ok "Flatpak ready"
}

SYSTEM_PKGS="zsh git curl htop vim qbittorrent btop bat"
DEV_PKGS="python3 php filezilla"
FLATPAK_BROWSERS="com.google.Chrome com.microsoft.Edge"
FLATPAK_APPS="org.videolan.VLC org.telegram.desktop com.discordapp.Discord com.stremio.Stremio org.libreoffice.LibreOffice com.spotify.Client"

install_flatpak_list() {
    for pkg in $1; do
        flatpak_installed "$pkg" && ok "$pkg already installed" || { msg "Installing Flatpak $pkg…"; progress; flatpak install -y "$pkg"; }
    done
}

setup_git() {
    local NAME EMAIL
    NAME=$(git config --global user.name || true)
    EMAIL=$(git config --global user.email || true)
    [[ -n "$NAME" && -n "$EMAIL" ]] && ok "Git already configured: $NAME <$EMAIL>" && return
    read -rp "Git user.name: " NAME
    read -rp "Git user.email: " EMAIL
    git config --global user.name "$NAME"
    git config --global user.email "$EMAIL"
    git config --global init.defaultBranch main
    git config --global color.ui auto
    ok "Git configured"
}

setup_zsh() {
    msg "Configuring Zsh…"; progress
    install_pkg zsh
    [[ ! -d "$HOME/.oh-my-zsh" ]] && RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Zsh ready"
    msg "Setting default shell to Zsh"
    chsh -s "$(command -v zsh)" "$USER"
}

install_nvm() {
    [[ -d "$HOME/.nvm" ]] && ok "NVM already installed" && return
    msg "Installing NVM…"; progress
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    ok "NVM installed"
}

install_docker() {
    bin_exists docker && ok "Docker already installed" && return
    msg "Installing Docker…"; progress
    case "$PKG" in
        apt|dnf) curl -fsSL https://get.docker.com | sudo sh ;;
        pacman)
            sudo pacman -Syu --noconfirm docker docker-compose
            sudo systemctl enable --now docker
            sudo usermod -aG docker "$USER"
        ;;
    esac
    ok "Docker installed"
}

install_vscode() {
    bin_exists code && ok "VS Code already installed" && return
    msg "Installing VS Code…"; progress
    case "$PKG" in
        apt)
            wget -qO vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
            sudo dpkg -i vscode.deb || sudo apt --fix-broken install -y
            rm vscode.deb
        ;;
        dnf)
            wget -qO vscode.rpm "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"
            sudo dnf install -y vscode.rpm
            rm vscode.rpm
        ;;
        pacman) sudo pacman -Sy --noconfirm code ;;
    esac
}

install_termius() {
    [[ "$PKG" != "apt" ]] && return
    bin_exists termius-app && ok "Termius already installed" && return
    msg "Installing Termius…"; progress
    wget -qO termius.deb https://autoupdate.termius.com/linux/Termius.deb
    sudo dpkg -i termius.deb || sudo apt --fix-broken install -y
    rm termius.deb
    ok "Termius installed"
}

echo -e "${MAGENTA}Profiles:${RESET}"
echo "1) minimal"
echo "2) dev"
echo "3) full"
read -rp "> " PROFILE

install_minimal() {
    for pkg in $SYSTEM_PKGS; do install_pkg "$pkg"; done
    setup_zsh
}

install_dev() {
    install_minimal
    for pkg in $DEV_PKGS; do install_pkg "$pkg"; done
    install_vscode
    install_nvm
    install_docker
    setup_git
}

install_full() {
    install_dev
    ensure_flatpak
    install_flatpak_list "$FLATPAK_BROWSERS"
    install_flatpak_list "$FLATPAK_APPS"
    install_termius
}

case "$PROFILE" in
    1) install_minimal ;;
    2) install_dev ;;
    3) install_full ;;
esac

msg "Final cleanup…"; progress
apt_full_fix
ok "Done!"

echo -e "${CYAN}Restart session to enable Zsh? (y/n):${RESET}"
read -r R
[[ "$R" =~ ^[Yy]$ ]] && exec zsh
