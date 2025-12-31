#!/bin/bash
# Script cài đặt Wine để chạy file .exe trên Ubuntu

set -euo pipefail

echo "=========================================="
echo "  Cài đặt Wine để chạy file .exe"
echo "=========================================="
echo ""

# Cập nhật hệ thống
echo "[1/5] Đang cập nhật hệ thống..."
sudo apt update

# Cài đặt Wine và các dependencies
echo "[2/5] Đang cài đặt Wine..."
sudo apt install -y wine64 wine32 winetricks

# Cấu hình Wine (32-bit)
echo "[3/5] Đang cấu hình Wine..."
winecfg &
sleep 5
pkill winecfg 2>/dev/null || true

# Cài đặt các component cần thiết
echo "[4/5] Đang cài đặt Windows components..."
winetricks -q corefonts vcrun2019 vcrun2015 vcrun2013

# Tạo shortcut
echo "[5/5] Hoàn tất!"
echo ""
echo "=========================================="
echo "  Wine đã được cài đặt thành công!"
echo "=========================================="
echo ""
echo "Cách sử dụng:"
echo "  wine yourfile.exe"
echo "  hoặc"
echo "  wine64 yourfile.exe"
echo ""
echo "Để cấu hình Wine:"
echo "  winecfg"
echo ""

