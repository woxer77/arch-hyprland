#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

USER_HOME="/home/$USER"

# reflector configuration (arch servers installation)
echo "[+] Configuring mirrorlist with reflector..."
sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# Ask user about OpenVPN
echo ""
read -p "[?] Will you be using OpenVPN? (y/n): " use_openvpn

if [[ "$use_openvpn" =~ ^[Yy]$ ]]; then
  echo "[+] Configuring sudoers for OpenVPN..."
  echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/killall openvpn, /usr/sbin/openvpn --config $USER_HOME/.config/openvpn/openvpn.ovpn --daemon" | sudo tee -a /etc/sudoers
  echo "[!] REMINDER: Place your '.ovpn' configuration file in '$USER_HOME/.config/openvpn/openvpn.ovpn'"
else
  echo "[+] OpenVPN not needed, removing OpenVPN package and config..."
  # Remove OpenVPN package if installed
  if pacman -Qi openvpn &>/dev/null; then
    sudo pacman -Rns --noconfirm openvpn || true
  fi
  # Remove OpenVPN config directory
  rm -rf "$USER_HOME/.config/openvpn" 2>/dev/null || true
  echo "[+] OpenVPN removed successfully"
fi

# Configure sudoers for Waybar CPU power monitoring
echo "[+] Configuring sudoers for Waybar CPU power monitoring..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/cat" | sudo tee /etc/sudoers.d/10_waybar_cpu_power
sudo chmod 0440 /etc/sudoers.d/10_waybar_cpu_power
echo "[✓] Waybar CPU power monitoring configured successfully"

# Configure sudoers for Waybar GPU power monitoring
echo "[+] Configuring sudoers for Waybar GPU power monitoring..."
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/cat" | sudo tee /etc/sudoers.d/11_waybar_gpu_power
sudo chmod 0440 /etc/sudoers.d/11_waybar_gpu_power
echo "[✓] Waybar GPU power monitoring configured successfully"

# Automatically mount disks so they can be accessible
echo "[+] Configuring automatic disk mounting..."
echo "# Entry for 1TB HDD (sda1)" | sudo tee -a /etc/fstab 
echo "UUID=9E9A93F69A93C8E3 /mnt/d ntfs-3g defaults,nofail 0 0" | sudo tee -a /etc/fstab
echo "# Entry for 1TB NVMe (nvme1n1p5)" | sudo tee -a /etc/fstab
echo "UUID=6A18EBE718EBAFED /mnt/e ntfs-3g defaults,nofail 0 0" | sudo tee -a /etc/fstab

# Enable GDM (display manager)
echo "[+] Enabling GDM display manager..."
sudo systemctl enable gdm

# Configure and enable firewall (ufw)
echo "[+] Configuring firewall (ufw)..."
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
echo "[✓] Firewall configured and enabled successfully"

echo "[✓] System configuration completed!"
