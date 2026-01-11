#!/bin/bash

energy1=$(sudo cat /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj 2>/dev/null)

if [ -z "$energy1" ]; then
    echo "0 W"
    exit 0
fi

sleep 1

energy2=$(sudo cat /sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj 2>/dev/null)

if [ -z "$energy2" ]; then
    echo "0 W"
    exit 0
fi

# P = ΔE / Δt
# Δt = 1s
energy_diff=$((energy2 - energy1))
power_uw=$((energy_diff / 1))
power_w=$((power_uw / 1000000))

if [ "$power_w" -lt 2 ]; then
    power_w=2
fi

echo "${power_w}W"
