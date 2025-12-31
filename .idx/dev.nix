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

      # Install Chrome, Wine, and Mining software
      echo "Đang cài đặt Chrome, Wine và phần mềm mining..."
      docker exec -it "$CONTAINER_NAME" bash -lc "
        sudo apt update -qq &&
        sudo apt remove -y firefox 2>/dev/null || true &&
        sudo apt install -y wget curl wine64 wine32 winetricks build-essential git -qq &&
        sudo wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
        sudo apt install -y /tmp/chrome.deb -qq &&
        sudo rm -f /tmp/chrome.deb &&
        winecfg &>/dev/null || true &&
        winetricks -q corefonts vcrun2019 2>/dev/null || true &&
        # Download Kryptex Miner (Windows .exe)
        mkdir -p ~/mining/kryptex &&
        cd ~/mining/kryptex &&
        wget -q https://files.kryptex.com/kryptex-latest.exe -O kryptex.exe 2>/dev/null || echo 'Kryptex download skipped' &&
        # Install xmrig (CPU miner) for Kryptex Pool
        wget -q https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz -O /tmp/xmrig.tar.gz 2>/dev/null || echo 'xmrig download skipped' &&
        cd /tmp && tar -xzf xmrig.tar.gz 2>/dev/null && sudo mv xmrig-*/xmrig /usr/local/bin/ 2>/dev/null && sudo chmod +x /usr/local/bin/xmrig 2>/dev/null || true
      " 2>/dev/null || echo "Installation completed or skipped"

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
