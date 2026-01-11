#!/bin/bash

# Получить загрузку GPU в процентах
gpu_usage=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null || echo "0")

echo "${gpu_usage}"
