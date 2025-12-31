#!/bin/bash
# Script sửa lỗi MSR module để tăng hashrate

echo "Đang sửa lỗi MSR module..."

# Cài đặt msr-tools
sudo apt update
sudo apt install -y msr-tools

# Load MSR module
sudo modprobe msr 2>/dev/null || echo "MSR module already loaded"

# Set permissions (cần chạy với sudo)
echo "Để tăng hashrate, chạy xmrig với sudo:"
echo "sudo xmrig -o pool.kryptex.com:7777 -u YOUR_WALLET -p x --coin monero"

echo "✅ Hoàn tất!"

