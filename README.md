# RKVM - Ubuntu 22.04 VM Setup

Script tự động tạo và chạy Ubuntu 22.04 Virtual Machine với QEMU/KVM.

## Tính năng

- Tự động tải Ubuntu 22.04 cloud image
- Cấu hình cloud-init với user/password sẵn
- Hỗ trợ cả chế độ Console và GUI
- SSH port forwarding (port 24)

## Yêu cầu

- Linux với KVM support (hoặc QEMU trên Windows/Mac)
- QEMU/KVM
- cloud-localds (cloud-utils)

## Cách sử dụng

### 1. Chế độ Console (mặc định - không có GUI)

```bash
bash vm.sh
```

**Thông tin đăng nhập:**
- Username: `root` hoặc `ubuntu`
- Password: `root` hoặc `ubuntu`

### 2. Chế độ GUI (có giao diện đồ họa)

Có 2 cách:

#### Cách 1: Sửa script (đơn giản)

Mở file `vm.sh`, tìm dòng:
```bash
GUI_MODE=false
```

Đổi thành:
```bash
GUI_MODE=true
```

Sau đó chạy:
```bash
bash vm.sh
```

Sau khi đăng nhập vào VM, cài desktop environment:
```bash
apt update
apt install -y ubuntu-desktop-minimal
# Hoặc nhẹ hơn:
apt install -y xfce4 xfce4-goodies
```

Khởi động lại VM và bạn sẽ thấy giao diện desktop.

#### Cách 2: Dùng script riêng (vm-gui.sh)

```bash
bash vm-gui.sh
```

## Cấu hình

Có thể chỉnh sửa các thông số trong script:

- `MEMORY`: RAM (mặc định: 32768 = 32GB)
- `CPUS`: Số CPU cores (mặc định: 8)
- `SSH_PORT`: Port SSH forwarding (mặc định: 24)
- `DISK_SIZE`: Dung lượng ổ cứng (mặc định: 100G)
- `GUI_MODE`: Bật/tắt GUI (mặc định: false)

## SSH vào VM

Sau khi VM chạy, bạn có thể SSH vào từ máy host:

```bash
ssh -p 24 root@localhost
# hoặc
ssh -p 24 ubuntu@localhost
```

Password: `root` hoặc `ubuntu`

## Lưu ý

- Lần đầu chạy sẽ mất thời gian để tải image (~600MB)
- Đợi 1-2 phút sau khi VM boot để cloud-init hoàn tất
- Để có GUI, cần cài desktop environment sau khi vào VM (mất 10-20 phút)
- VM files được lưu tại `~/vm` (hoặc `~/vm-gui` cho GUI mode)

## Chạy file .exe trên Ubuntu (Wine)

Để chạy các file Windows (.exe) trên Ubuntu VM:

### Cài đặt Wine tự động

```bash
# Copy script install-wine.sh vào VM (hoặc tạo trực tiếp trong VM)
bash install-wine.sh
```

### Cài đặt thủ công

```bash
sudo apt update
sudo apt install -y wine64 wine32 winetricks
winecfg  # Cấu hình Wine (có thể đóng cửa sổ)
```

### Sử dụng

```bash
# Chạy file .exe
wine yourfile.exe

# Hoặc click đúp vào file .exe trong file manager
```

**Lưu ý:** Không phải tất cả .exe đều chạy được trên Wine. Một số ứng dụng có thể cần thêm cấu hình.

## Troubleshooting

**Login incorrect?**
- Đợi thêm 1-2 phút để cloud-init hoàn tất
- Đảm bảo nhập đúng: username `root`/`ubuntu`, password `root`/`ubuntu`
- Caps Lock phải tắt

**Không thấy GUI?**
- Đảm bảo đã set `GUI_MODE=true`
- Đã cài desktop environment trong VM chưa?
- Thử khởi động lại VM

**File .exe không chạy?**
- Đảm bảo đã cài Wine: `sudo apt install -y wine64 wine32`
- Thử cài thêm components: `winetricks vcrun2019 corefonts`
- Kiểm tra log: `wine yourfile.exe 2>&1 | less`

## VPS FREE cho Windows

Script tạo VPS miễn phí với Docker + noVNC (tương đương https://github.com/phuonganhnguyen1842-ctrl/vps.git)

### Yêu cầu
- Windows 10/11
- Docker Desktop (tải tại: https://www.docker.com/products/docker-desktop)

### Cách sử dụng

**Phiên bản Local (chỉ truy cập từ máy local):**
```powershell
.\vps-windows.ps1
```

**Phiên bản với Cloudflare Tunnel (truy cập từ bất kỳ đâu):**
```powershell
.\vps-windows-cloudflare.ps1
```

### Thông tin đăng nhập
- **URL**: http://localhost:10000 (local) hoặc Cloudflare URL (nếu dùng cloudflare version)
- **Mật khẩu VNC**: `12345678`

### Lệnh hữu ích
```powershell
# Xem container đang chạy
docker ps

# Dừng VPS
docker stop ubuntu-novnc

# Khởi động lại VPS
docker start ubuntu-novnc

# Xóa VPS
docker rm -f ubuntu-novnc
```

