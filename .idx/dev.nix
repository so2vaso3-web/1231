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

      # Check if Windows container can run (requires Windows host)
      if docker info 2>/dev/null | grep -q "Operating System.*Windows"; then
        echo "Windows host detected - using Windows container"
        CONTAINER_NAME="windows-rdp"
        IMAGE="danielguerra/ubuntu-xrdp"
        
        # For Windows, we'll use a Linux container with Windows-like environment
        # or use Windows Server Core with RDP
        IMAGE="mcr.microsoft.com/windows/servercore:ltsc2022"
      else
        echo "Linux host detected - using Windows-like container"
        # Use a container that provides Windows-like experience on Linux
        CONTAINER_NAME="windows-novnc"
        IMAGE="danielguerra/windows-xrdp"
      fi

      # Pull and start container
      if ! docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        echo "Đang tải Windows container image..."
        docker pull "$IMAGE" || {
          echo "Trying alternative Windows-like container..."
          IMAGE="accetto/ubuntu-vnc-xfce"
          CONTAINER_NAME="windows-novnc"
          docker pull "$IMAGE"
        }
        
        echo "Đang khởi động container..."
        docker run --name "$CONTAINER_NAME" \
          --shm-size 1g -d \
          --cap-add=SYS_ADMIN \
          -p 10000:10000 \
          -e VNC_PASSWD=12345678 \
          -e PORT=10000 \
          -e SCREEN_WIDTH=1024 \
          -e SCREEN_HEIGHT=768 \
          "$IMAGE"
      else
        docker start "$CONTAINER_NAME" || true
      fi

      # Wait for container to be ready
      echo "Đang chờ container sẵn sàng..."
      while ! nc -z localhost 10000; do sleep 1; done

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
        echo " 🌍 Windows VPS đã sẵn sàng:"
        echo "   $URL"
        echo "  Mật khẩu VPS: 12345678"
        echo "=========================================="
        echo ""
      else
        echo "Local URL: http://localhost:10000"
        echo "Password: 12345678"
      fi

      # Keep script alive
      elapsed=0
      while true; do 
        echo "Windows VPS đang chạy... Đã chạy: $elapsed phút"
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
