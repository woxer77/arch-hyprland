#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="${REPO_DIR:-$(pwd)}"

# Download fonts
echo "[+] Downloading RubikWetPaint font..."
mkdir -p "$HOME/.local/share/fonts"
wget -q -O "$HOME/.local/share/fonts/RubikWetPaint-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/rubikwetpaint/RubikWetPaint-Regular.ttf

# Copy configuration files
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
gtk-icon-theme-name=Papirus
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

# Apply Mousepad settings
if [ -f "$REPO_DIR/configs/mousepad-settings.txt" ]; then
  echo "[+] Applying Mousepad settings..."
  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Apply setting using dconf
    dconf load /org/xfce/mousepad/ <<< "$line"
  done < "$REPO_DIR/configs/mousepad-settings.txt"
  echo "[+] Mousepad settings applied successfully!"
else
  echo "[-] File configs/mousepad-settings.txt not found!"
fi

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

echo "[✓] User configurations applied successfully!"
