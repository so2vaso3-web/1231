# VPS FREE với Docker + noVNC trên Windows
# Tương đương với: https://github.com/phuonganhnguyen1842-ctrl/vps.git

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VPS FREE - Windows Version" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Docker Desktop
Write-Host "[1/5] Kiểm tra Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✓ Docker đã được cài đặt" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker chưa được cài đặt!" -ForegroundColor Red
    Write-Host "Vui lòng cài Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Kiểm tra Docker đang chạy
try {
    docker ps | Out-Null
    Write-Host "✓ Docker đang chạy" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker chưa chạy! Vui lòng khởi động Docker Desktop" -ForegroundColor Red
    exit 1
}

# Tạo thư mục làm việc
Write-Host "[2/5] Tạo thư mục làm việc..." -ForegroundColor Yellow
$workDir = "$env:USERPROFILE\vps"
if (-not (Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}
Set-Location $workDir
Write-Host "✓ Thư mục: $workDir" -ForegroundColor Green

# Pull và start container
Write-Host "[3/5] Đang tải và khởi động Docker container..." -ForegroundColor Yellow
$containerName = "ubuntu-novnc"
$containerExists = docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$containerName$"

if (-not $containerExists) {
    Write-Host "Đang tải image (có thể mất vài phút)..." -ForegroundColor Yellow
    docker pull thuonghai2711/ubuntu-novnc-pulseaudio:22.04
    
    Write-Host "Đang khởi động container..." -ForegroundColor Yellow
    docker run --name $containerName `
        --shm-size 1g -d `
        --cap-add=SYS_ADMIN `
        -p 10000:10000 `
        -e VNC_PASSWD=12345678 `
        -e PORT=10000 `
        -e AUDIO_PORT=1699 `
        -e WEBSOCKIFY_PORT=6900 `
        -e VNC_PORT=5900 `
        -e SCREEN_WIDTH=1024 `
        -e SCREEN_HEIGHT=768 `
        -e SCREEN_DEPTH=24 `
        thuonghai2711/ubuntu-novnc-pulseaudio:22.04
    
    Write-Host "✓ Container đã được tạo và khởi động" -ForegroundColor Green
} else {
    Write-Host "Container đã tồn tại, đang khởi động..." -ForegroundColor Yellow
    docker start $containerName | Out-Null
    Write-Host "✓ Container đã khởi động" -ForegroundColor Green
}

# Đợi container sẵn sàng
Write-Host "[4/5] Đang chờ container sẵn sàng..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
$maxAttempts = 30
$attempt = 0
while ($attempt -lt $maxAttempts) {
    try {
        $response = Test-NetConnection -ComputerName localhost -Port 10000 -WarningAction SilentlyContinue
        if ($response.TcpTestSucceeded) {
            Write-Host "✓ Container đã sẵn sàng" -ForegroundColor Green
            break
        }
    } catch {}
    $attempt++
    Start-Sleep -Seconds 1
}

# Cài Chrome trong container
Write-Host "[5/5] Đang cài đặt Chrome trong container..." -ForegroundColor Yellow
docker exec -it $containerName bash -lc @"
sudo apt update &&
sudo apt remove -y firefox 2>/dev/null || true &&
sudo apt install -y wget &&
sudo wget -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
sudo apt install -y /tmp/chrome.deb &&
sudo rm -f /tmp/chrome.deb
"@ | Out-Null
Write-Host "✓ Chrome đã được cài đặt" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VPS đã sẵn sàng!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Truy cập VPS tại: http://localhost:10000" -ForegroundColor Yellow
Write-Host "Mật khẩu VNC: 12345678" -ForegroundColor Yellow
Write-Host ""
Write-Host "Để dừng VPS: docker stop $containerName" -ForegroundColor Gray
Write-Host "Để khởi động lại: docker start $containerName" -ForegroundColor Gray
Write-Host ""

# Mở trình duyệt tự động
Start-Process "http://localhost:10000"

Write-Host "Đang chạy... (Nhấn Ctrl+C để dừng)" -ForegroundColor Gray
Write-Host ""

# Giữ script chạy
try {
    while ($true) {
        Start-Sleep -Seconds 60
        $elapsed = [math]::Floor((Get-Date) - $scriptStart).TotalMinutes
        Write-Host "VPS đang chạy - Đã chạy: $elapsed phút" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "`nĐang dừng..." -ForegroundColor Yellow
}

