#!/bin/bash
# Script cài đặt mining software thủ công nếu auto-install không chạy

echo "Đang cài đặt Wine và mining software..."

sudo apt update
sudo apt install -y wine wine64 wine32 winetricks wget curl build-essential git unzip

# Cài xmrig
cd /tmp
XMRIG_VER=$(curl -s https://api.github.com/repos/xmrig/xmrig/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
wget https://github.com/xmrig/xmrig/releases/download/v${XMRIG_VER}/xmrig-${XMRIG_VER}-linux-x64.tar.gz
tar -xzf xmrig-*.tar.gz
sudo mv xmrig-*/xmrig /usr/local/bin/
sudo chmod +x /usr/local/bin/xmrig
rm -rf /tmp/xmrig*

# Tải Kryptex
mkdir -p ~/mining/kryptex
cd ~/mining/kryptex
wget https://files.kryptex.com/kryptex-latest.exe -O kryptex.exe || echo "Kryptex download failed"

# Cấu hình Wine
winecfg &>/dev/null || true
winetricks -q corefonts vcrun2019 2>/dev/null || true

echo "✅ Cài đặt hoàn tất!"
echo "Chạy: wine ~/mining/kryptex/kryptex.exe"
echo "Hoặc: xmrig -o pool.kryptex.com:7777 -u YOUR_WALLET -p x --coin monero"

