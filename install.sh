#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(pwd)"
export REPO_DIR

echo "=========================================="
echo "  Hyprland Environment Installation"
echo "=========================================="
echo ""

# Git configuration
echo "[+] Git Configuration"
read -p "Enter your git email: " git_email
read -p "Enter your git username: " git_username

git config --global user.email "$git_email"
git config --global user.name "$git_username"

echo "[✓] Git configured successfully!"
echo ""

# Execute installation modules
echo "[+] Step 1/3: System setup and package installation..."
bash "$REPO_DIR/install-scripts/01-system-setup.sh"

echo ""
echo "[+] Step 2/3: User configurations..."
bash "$REPO_DIR/install-scripts/02-user-configs.sh"

echo ""
echo "[+] Step 3/3: System configurations..."
bash "$REPO_DIR/install-scripts/03-system-configs.sh"

# Final reminders
echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo "[!] REMINDER: Don't forget to configure .ssh for GitHub"
echo "[!] REMINDER: Don't forget to execute spicetify.sh if needed"
echo ""
echo "[✓] Hyprland environment successfully installed and configured!"
