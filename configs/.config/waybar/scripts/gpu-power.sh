#!/bin/bash

# Получить потребление мощности GPU в микроваттах и конвертировать в ватты
power_uw=$(cat /sys/class/hwmon/hwmon2/power1_average 2>/dev/null || echo "0")
power_w=$((power_uw / 1000000))

echo "${power_w}W"
