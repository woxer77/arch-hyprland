#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="${REPO_DIR:-$(pwd)}"

# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
  echo "[-] Do not run this script as root. Use a normal user with sudo privileges."
  exit 1
fi

# System update and base tool installation
echo "[+] Updating system and installing essential tools..."
sudo pacman -Syu --noconfirm git wget curl base base-devel sudo

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
  echo "[+] Installing yay (AUR helper)..."
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
  rm -rf /tmp/yay
else
  echo "[+] yay is already installed"
fi

# Install packages from pacman.txt
if [ -f "$REPO_DIR/packages/pacman.txt" ]; then
  echo "[+] Installing packages from pacman.txt..."
  sudo pacman -Sy --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/pacman.txt")
else
  echo "[-] File packages/pacman.txt not found!"
fi

# Install packages from yay.txt
if [ -f "$REPO_DIR/packages/yay.txt" ]; then
  echo "[+] Installing AUR packages from yay.txt..."
  yay -Sy --needed --noconfirm $(grep -vE '^\s*#|^\s*$' "$REPO_DIR/packages/yay.txt")
else
  echo "[-] File packages/yay.txt not found!"
fi

echo "[✓] System setup and package installation completed!"
