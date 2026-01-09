#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

USER_HOME="/home/$USER"
REPO_DIR="$(pwd)"

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

# Download fonts
echo "[+] Downloading RubikWetPaint font..."
mkdir -p "$HOME/.local/share/fonts"
wget -q -O "$HOME/.local/share/fonts/RubikWetPaint-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf

# Copy configuration files (after packages are installed)
echo "[+] Copying configuration files..."
[ -d "$REPO_DIR/configs/.config" ] && cp -r "$REPO_DIR/configs/.config" "$HOME/"
[ -f "$REPO_DIR/configs/.bashrc" ] && cp "$REPO_DIR/configs/.bashrc" "$HOME/.bashrc"
[ -f "$REPO_DIR/configs/.bash_profile" ] && cp "$REPO_DIR/configs/.bash_profile" "$HOME/.bash_profile"

# Fix config permissions
chmod -R 755 "$HOME/.config" 2>/dev/null || true

# Apply GTK theme and icons
echo "[+] Applying GTK theme and icons..."
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.config/gtk-4.0"

# GTK 3 settings
cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Flamingo-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF

# GTK 4 settings
cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Flamingo-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

# Apply settings using gsettings (for GNOME apps)
if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha-Standard-Flamingo-Dark'
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi

echo "[+] Theme 'Catppuccin-Mocha-Standard-Flamingo-Dark' and icons 'Papirus-Dark' applied successfully!"

# Set default image viewer
echo "[+] Setting default image viewer to GNOME Loupe..."
xdg-mime default org.gnome.Loupe.desktop image/jpeg
xdg-mime default org.gnome.Loupe.desktop image/png
xdg-mime default org.gnome.Loupe.desktop image/gif
xdg-mime default org.gnome.Loupe.desktop image/webp
xdg-mime default org.gnome.Loupe.desktop image/bmp
xdg-mime default org.gnome.Loupe.desktop image/svg+xml

# Create Downloads directory
mkdir -p "$HOME/Downloads"

# Copy custom scripts to /usr/local/bin
echo "[+] Installing custom user scripts..."
if [ -d "$REPO_DIR/scripts" ]; then
  sudo cp "$REPO_DIR/scripts/volume-down.sh" /usr/local/bin/
  sudo cp "$REPO_DIR/scripts/volume-up.sh" /usr/local/bin/
fi

# Copy wallpapers
if [ -d "$REPO_DIR/Wallpapers" ]; then
  cp -r "$REPO_DIR/Wallpapers" "$HOME/Wallpapers"
fi

# reflector configuration (arch servers installation)
sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# Configuring sudoers
echo "[+] Configuring sudoers..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/killall openvpn, /usr/sbin/openvpn --config $USER_HOME/.config/openvpn/openvpn.ovpn --daemon" | sudo tee -a /etc/sudoers

# Automatically mount disks so they can be accessible
echo "# Entry for 1TB HDD (sda1)" | sudo tee -a /etc/fstab 
echo "UUID=9E9A93F69A93C8E3 /mnt/d ntfs-3g defaults,nofail 0 0" | sudo tee -a /etc/fstab
echo "# Entry for 1TB NVMe (nvme1n1p5)" | sudo tee -a /etc/fstab
echo "UUID=6A18EBE718EBAFED /mnt/e ntfs-3g defaults,nofail 0 0" | sudo tee -a /etc/fstab

# Success

echo "[!] REMINDER: For OpenVPN place '.ovpn' configuration file in '$HOME/.config/openvpn/openvpn.ovpn'"
echo "[!] REMINDER: Don't forget to configure .ssh for GitHub"
echo "[!] REMINDER: Don't forget to execute spicetify.ssh if needed"

echo "[✓] Hyprland environment successfully installed and configured!"
