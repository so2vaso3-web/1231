{ pkgs, ... }: {
  channel = "stable-24.11";

  packages = [
    pkgs.docker
    pkgs.cloudflared
    pkgs.socat
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.sudo
    pkgs.unzip
    pkgs.netcat
  ];

  services.docker.enable = true;

  idx.workspace.onStart = {
    windows = ''
      set -e

      # Make sure current directory exists
      mkdir -p ~/vps
      cd ~/vps

      # One-time cleanup
      if [ ! -f /home/user/.cleanup_done ]; then
        rm -rf /home/user/.gradle/* /home/user/.emu/* 2>/dev/null || true
        find /home/user -mindepth 1 -maxdepth 1 ! -name 'idx-ubuntu22-gui' ! -name '.*' -exec rm -rf {} + 2>/dev/null || true
        touch /home/user/.cleanup_done
      fi

      CONTAINER_NAME="windows-novnc"
      IMAGE="thuonghai2711/ubuntu-novnc-pulseaudio:22.04"

      # Pull and start container
      if ! docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        echo "Đang tải container image..."
        docker pull "$IMAGE"
        
        echo "Đang khởi động container..."
        docker run --name "$CONTAINER_NAME" \
          --shm-size 1g -d \
          --cpus="4.0" \
          --cap-add=SYS_ADMIN \
          -p 10000:10000 \
          -e VNC_PASSWD=12345678 \
          -e PORT=10000 \
          -e AUDIO_PORT=1699 \
          -e WEBSOCKIFY_PORT=6900 \
          -e VNC_PORT=5900 \
          -e SCREEN_WIDTH=1024 \
          -e SCREEN_HEIGHT=768 \
          -e SCREEN_DEPTH=24 \
          "$IMAGE"
      else
        docker start "$CONTAINER_NAME" || true
      fi

      # Wait for container to be ready
      echo "Đang chờ container sẵn sàng..."
      while ! nc -z localhost 10000; do sleep 1; done

      # Install Chrome, Wine, and Mining software automatically
      echo "Đang tự động cài đặt Chrome, Wine và phần mềm mining..."
      sleep 5
      docker exec "$CONTAINER_NAME" bash -c "
        sudo apt update -qq &&
        sudo apt remove -y firefox 2>/dev/null || true &&
        sudo apt install -y wget curl wine wine64 wine32 winetricks build-essential git unzip -qq &&
        sudo apt install -y --fix-missing 2>/dev/null || true &&
        sudo wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
        sudo apt install -y /tmp/chrome.deb -qq &&
        sudo rm -f /tmp/chrome.deb &&
        export DISPLAY=:0 &&
        winecfg &>/dev/null || true &&
        winetricks -q corefonts vcrun2019 vcrun2015 2>/dev/null || true &&
        # Create mining directory
        mkdir -p /home/ubuntu/mining/kryptex &&
        mkdir -p /home/ubuntu/mining/xmrig &&
        cd /home/ubuntu/mining/kryptex &&
        # Download Kryptex Miner
        wget -q --timeout=30 https://files.kryptex.com/kryptex-latest.exe -O kryptex.exe 2>/dev/null || wget -q --timeout=30 https://kryptex.org/files/kryptex-latest.exe -O kryptex.exe 2>/dev/null || echo 'Kryptex download will retry later' &&
        # Install xmrig (CPU miner) for Kryptex Pool
        cd /tmp &&
        XMRIG_VER=\$(curl -s https://api.github.com/repos/xmrig/xmrig/releases/latest | grep tag_name | cut -d '\"' -f 4 | sed 's/v//') &&
        wget -q --timeout=30 https://github.com/xmrig/xmrig/releases/download/v\${XMRIG_VER}/xmrig-\${XMRIG_VER}-linux-x64.tar.gz -O xmrig.tar.gz 2>/dev/null &&
        tar -xzf xmrig.tar.gz 2>/dev/null &&
        sudo mv xmrig-*/xmrig /usr/local/bin/ 2>/dev/null &&
        sudo chmod +x /usr/local/bin/xmrig 2>/dev/null &&
        sudo rm -rf /tmp/xmrig* 2>/dev/null || echo 'xmrig installation completed or skipped' &&
        # Create auto-start script
        echo '#!/bin/bash' > /home/ubuntu/start-mining.sh &&
        echo 'cd ~/mining/kryptex' >> /home/ubuntu/start-mining.sh &&
        echo 'if [ -f kryptex.exe ]; then' >> /home/ubuntu/start-mining.sh &&
        echo '  wine kryptex.exe &' >> /home/ubuntu/start-mining.sh &&
        echo 'else' >> /home/ubuntu/start-mining.sh &&
        echo '  echo \"Downloading Kryptex...\"' >> /home/ubuntu/start-mining.sh &&
        echo '  wget https://files.kryptex.com/kryptex-latest.exe -O kryptex.exe' >> /home/ubuntu/start-mining.sh &&
        echo '  wine kryptex.exe &' >> /home/ubuntu/start-mining.sh &&
        echo 'fi' >> /home/ubuntu/start-mining.sh &&
        chmod +x /home/ubuntu/start-mining.sh &&
        # Create desktop shortcut
        mkdir -p /home/ubuntu/Desktop &&
        echo '[Desktop Entry]' > /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo 'Version=1.0' >> /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo 'Type=Application' >> /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo 'Name=Kryptex Miner' >> /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo 'Exec=/home/ubuntu/start-mining.sh' >> /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo 'Icon=application-x-executable' >> /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        chmod +x /home/ubuntu/Desktop/Kryptex-Miner.desktop &&
        echo '✅ Tất cả đã được cài đặt tự động!'
      " 2>&1 | grep -v "^$" || echo "Installation in progress..."

      # Run Cloudflared tunnel
      echo "Đang khởi động Cloudflared tunnel..."
      nohup cloudflared tunnel --no-autoupdate --url http://localhost:10000 \
        > /tmp/cloudflared.log 2>&1 &

      # Wait for tunnel
      sleep 10

      # Extract Cloudflared URL
      URL=""
      for i in {1..15}; do
        URL=$(grep -o "https://[a-z0-9.-]*trycloudflare.com" /tmp/cloudflared.log 2>/dev/null | head -n1)
        if [ -n "$URL" ]; then break; fi
        sleep 1
      done

      if [ -n "$URL" ]; then
        echo ""
        echo "========================================="
        echo " 🌍 VPS đã sẵn sàng (Ubuntu + Wine):"
        echo "   $URL"
        echo "  Mật khẩu VPS: 12345678"
        echo ""
        echo "  ⚠️  Lưu ý: Đây là Ubuntu + Wine"
        echo "  ✅ Có thể chạy file .exe bằng Wine"
        echo "  ✅ Đã cài sẵn Wine, Chrome"
        echo "=========================================="
        echo ""
      else
        echo "Local URL: http://localhost:10000"
        echo "Password: 12345678"
        echo "Đã cài Wine để chạy .exe"
      fi

      # Keep script alive
      elapsed=0
      while true; do 
        echo "VPS đang chạy... Đã chạy: $elapsed phút"
        ((elapsed++))
        sleep 60
      done
    '';
  };

  idx.previews = {
    enable = true;
    previews = {
      windows = {
        manager = "web";
        command = [
          "bash" "-lc"
          "socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:10000"
        ];
      };
    };
  };
}
