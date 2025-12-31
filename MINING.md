# Hướng dẫn Mining với Kryptex trên Ubuntu

## Đã cài sẵn:

1. **Wine** - Để chạy Kryptex Miner (.exe)
2. **xmrig** - CPU miner cho Kryptex Pool
3. **Kryptex Miner** - Đã tải về tại `~/mining/kryptex/kryptex.exe`

## Cài đặt (nếu auto-install chưa chạy):

Nếu thấy lỗi "wine: command not found" hoặc "xmrig: command not found", chạy:

```bash
bash install-mining.sh
```

## Cách sử dụng:

### 1. Chạy Kryptex Miner (Windows .exe qua Wine):

```bash
cd ~/mining/kryptex
wine kryptex.exe
```

### 2. Hoặc dùng xmrig để mine trực tiếp vào Kryptex Pool:

```bash
# Thay YOUR_WALLET_ADDRESS bằng địa chỉ ví Monero của bạn
xmrig -o pool.kryptex.com:7777 -u YOUR_WALLET_ADDRESS -p x --coin monero

# Ví dụ:
# xmrig -o pool.kryptex.com:7777 -u 48abc123...xyz -p x --coin monero
```

**Lưu ý:** 
- Hiện tại đang **benchmark** (test), chưa đào thật
- Cần thay `YOUR_WALLET_ADDRESS` bằng địa chỉ ví thật
- Có lỗi MSR module → hashrate sẽ thấp hơn (không ảnh hưởng việc đào)

### 3. Tải Kryptex Miner mới nhất:

```bash
cd ~/mining/kryptex
wget https://files.kryptex.com/kryptex-latest.exe -O kryptex.exe
wine kryptex.exe
```

## Tham khảo:

- Kryptex Pool: https://pool.kryptex.com
- Hướng dẫn Ubuntu Mining: https://pool.kryptex.com/articles/ubuntu-gpu-mining-en

