#!/bin/bash
# Выбирает случайный обои из папки Wallpapers для hyprlock

WALLPAPER=$(find /home/woxer/Wallpapers -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1)
ln -sf "$WALLPAPER" /tmp/hyprlock-wallpaper.png
