# VPS FREE với Cloudflare Tunnel trên Windows
# Phiên bản đầy đủ với Cloudflare Tunnel (giống repo gốc)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VPS FREE - Windows + Cloudflare" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Docker
Write-Host "[1/6] Kiểm tra Docker..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    docker ps | Out-Null
    Write-Host "✓ Docker OK" -ForegroundColor Green
} catch {
    Write-Host "✗ Cần Docker Desktop!" -ForegroundColor Red
    exit 1
}

# Kiểm tra Cloudflared
Write-Host "[2/6] Kiểm tra Cloudflared..." -ForegroundColor Yellow
$cloudflaredPath = "$env:USERPROFILE\.cloudflared\cloudflared.exe"
if (-not (Test-Path $cloudflaredPath)) {
    Write-Host "Đang tải Cloudflared..." -ForegroundColor Yellow
    $cloudflaredDir = "$env:USERPROFILE\.cloudflared"
    New-Item -ItemType Directory -Force -Path $cloudflaredDir | Out-Null
    
    # Tải Cloudflared cho Windows
    $cloudflaredUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    Invoke-WebRequest -Uri $cloudflaredUrl -OutFile $cloudflaredPath
    Write-Host "✓ Cloudflared đã được tải" -ForegroundColor Green
} else {
    Write-Host "✓ Cloudflared đã có sẵn" -ForegroundColor Green
}

# Tạo thư mục
$workDir = "$env:USERPROFILE\vps"
if (-not (Test-Path $workDir)) {
    New-Item -ItemType Directory -Path $workDir | Out-Null
}
Set-Location $workDir

# Docker container
Write-Host "[3/6] Khởi động Docker container..." -ForegroundColor Yellow
$containerName = "ubuntu-novnc"
$exists = docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$containerName$"

if (-not $exists) {
    docker pull thuonghai2711/ubuntu-novnc-pulseaudio:22.04
    docker run --name $containerName `
        --shm-size 1g -d `
        --cap-add=SYS_ADMIN `
        -p 10000:10000 `
        -e VNC_PASSWD=12345678 `
        -e PORT=10000 `
        thuonghai2711/ubuntu-novnc-pulseaudio:22.04
} else {
    docker start $containerName | Out-Null
}

# Đợi container
Write-Host "[4/6] Đợi container sẵn sàng..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Cài Chrome
Write-Host "[5/6] Cài đặt Chrome..." -ForegroundColor Yellow
docker exec -it $containerName bash -lc @"
sudo apt update -qq &&
sudo apt remove -y firefox 2>/dev/null || true &&
sudo apt install -y wget -qq &&
sudo wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&
sudo apt install -y /tmp/chrome.deb -qq &&
sudo rm -f /tmp/chrome.deb
"@ | Out-Null

# Cloudflare Tunnel
Write-Host "[6/6] Khởi động Cloudflare Tunnel..." -ForegroundColor Yellow
$logFile = "$workDir\cloudflared.log"
Start-Process -FilePath $cloudflaredPath -ArgumentList "tunnel","--no-autoupdate","--url","http://localhost:10000" -NoNewWindow -RedirectStandardOutput $logFile -RedirectStandardError $logFile

Start-Sleep -Seconds 15

# Đọc URL từ log
$url = ""
for ($i = 1; $i -le 20; $i++) {
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw
        if ($content -match "https://[a-z0-9.-]*trycloudflare\.com") {
            $url = $matches[0]
            break
        }
    }
    Start-Sleep -Seconds 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
if ($url) {
    Write-Host "  🌍 Cloudflared Tunnel URL:" -ForegroundColor Cyan
    Write-Host "     $url" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ VPS Local URL:" -ForegroundColor Cyan
    Write-Host "     http://localhost:10000" -ForegroundColor Yellow
}
Write-Host "  Mật khẩu VNC: 12345678" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Giữ script chạy
Write-Host "VPS đang chạy... (Nhấn Ctrl+C để dừng)" -ForegroundColor Gray
try {
    while ($true) {
        Start-Sleep -Seconds 60
    }
} catch {
    Write-Host "`nĐang dừng VPS..." -ForegroundColor Yellow
    docker stop $containerName | Out-Null
}

