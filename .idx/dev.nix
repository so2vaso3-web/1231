{ pkgs, ... }: {
  channel = "stable-24.11";

  packages = [
    pkgs.docker
    pkgs.cloudflared
    pkgs.socat
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.sudo
    pkgs.apt
    pkgs.systemd
    pkgs.unzip
    pkgs.netcat
  ];

  services.docker.enable = true;

  idx.workspace.onStart = {
    novnc = ''
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

      # Pull and start container
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-novnc'; then
        echo "Đang tải Docker image..."
        docker pull thuonghai2711/ubuntu-novnc-pulseaudio:22.04
        echo "Đang khởi động container..."
        docker run --name ubuntu-novnc \
          --shm-size 1g -d \
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
          thuonghai2711/ubuntu-novnc-pulseaudio:22.04
      else
        docker start ubuntu-novnc || true
      fi

      # Wait for Novnc WebSocket port
      echo "Đang chờ container sẵn sàng..."
      while ! nc -z localhost 10000; do sleep 1; done

      # Install Chrome
      echo "Đang cài đặt Chrome..."
      docker exec -it ubuntu-novnc bash -lc "
        sudo apt update -qq &&
        sudo apt remove -y firefox 2>/dev/null || true &&
        sudo apt install -y wget -qq &&
        sudo wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
        sudo apt install -y /tmp/chrome.deb -qq &&
        sudo rm -f /tmp/chrome.deb
      " 2>/dev/null || echo "Chrome installation skipped or already installed"

      # Run Cloudflared tunnel
      echo "Đang khởi động Cloudflared tunnel..."
      nohup cloudflared tunnel --no-autoupdate --url http://localhost:10000 \
        > /tmp/cloudflared.log 2>&1 &

      # Wait a bit longer to ensure WebSocket is fully ready
      sleep 10

      # Extract Cloudflared URL reliably
      URL=""
      for i in {1..15}; do
        URL=$(grep -o "https://[a-z0-9.-]*trycloudflare.com" /tmp/cloudflared.log 2>/dev/null | head -n1)
        if [ -n "$URL" ]; then break; fi
        sleep 1
      done

      if [ -n "$URL" ]; then
        echo ""
        echo "========================================="
        echo " 🌍 Your Cloudflared tunnel is ready:"
        echo "   $URL"
        echo "  Mật khẩu VPS của bạn là: 12345678"
        echo "=========================================="
        echo ""
      else
        echo "❌ Cloudflared tunnel failed, check /tmp/cloudflared.log"
        echo "Local URL: http://localhost:10000"
        echo "Password: 12345678"
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
      novnc = {
        manager = "web";
        command = [
          "bash" "-lc"
          "socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:10000"
        ];
      };
    };
  };
}
