#!/bin/bash
set -euo pipefail

# =============================
# Ubuntu 22.04 Desktop VM (GUI Mode)
# =============================

clear
cat << "EOF"
================================================                    
            mmmmmm    mmmmm     mmm  mmm 
            ##""""##  ##"""##    ##mm##  
            ##    ##  ##    ##    ####   
            #######   ##    ##     ##    
            ##  "##m  ##    ##    ####   
            ##    ##  ##mmm##    ##  ##  
            ""    """ """""     """  """ 
           POWERED BY RDX - GUI MODE            
================================================
EOF

# =============================
# Configurable Variables
# =============================
VM_DIR="$HOME/vm-gui"
IMG_FILE="$VM_DIR/ubuntu-desktop.img"
SEED_FILE="$VM_DIR/seed.iso"
MEMORY=8192   # 8GB RAM (GUI needs more)
CPUS=4
SSH_PORT=25
DISK_SIZE=50G

mkdir -p "$VM_DIR"
cd "$VM_DIR"

# =============================
# VM Image Setup
# =============================
if [ ! -f "$IMG_FILE" ]; then
    echo "[INFO] VM Desktop image not found, creating new VM..."
    echo "[INFO] This will download Ubuntu Desktop (~5GB), please wait..."
    wget -q --show-progress https://cdimage.ubuntu.com/ubuntu-legacy-server/releases/22.04/release/ubuntu-22.04.3-legacy-server-amd64.img -O "$IMG_FILE" 2>&1 || \
    wget -q --show-progress https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O "$IMG_FILE"
    qemu-img resize "$IMG_FILE" "$DISK_SIZE"

    # Cloud-init config for Desktop
    cat > user-data <<EOF
#cloud-config
hostname: ubuntu22
manage_etc_hosts: true
disable_root: false
ssh_pwauth: true
chpasswd:
  list: |
    root:root
    ubuntu:ubuntu
  expire: false
users:
  - name: ubuntu
    lock_passwd: false
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: adm, cdrom, dip, plugdev, lpadmin, sambashare
package_update: true
package_upgrade: false
packages:
  - ubuntu-desktop-minimal
  - xfce4
  - xfce4-goodies
  - xrdp
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false
resize_rootfs: true
runcmd:
 - growpart /dev/vda 1 || true
 - resize2fs /dev/vda1 || true
 - sed -ri "s/^#?PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
 - systemctl restart ssh
 - systemctl enable xrdp
 - systemctl start xrdp || true
EOF

    cat > meta-data <<EOF
instance-id: iid-local01
local-hostname: ubuntu22
EOF

    cloud-localds "$SEED_FILE" user-data meta-data
    echo "[INFO] VM Desktop setup complete!"
else
    echo "[INFO] VM Desktop image found, skipping setup..."
fi

# =============================
# Start VM with GUI
# =============================
echo "[INFO] Starting VM with GUI..."
echo "[INFO] Login: root/root or ubuntu/ubuntu"
echo "[INFO] After first boot, install desktop: sudo apt update && sudo apt install -y ubuntu-desktop-minimal"
exec qemu-system-x86_64 \
    -enable-kvm \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -cpu host \
    -drive file="$IMG_FILE",format=qcow2,if=virtio \
    -drive file="$SEED_FILE",format=raw,if=virtio \
    -boot order=c \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,hostfwd=tcp::"$SSH_PORT"-:22 \
    -vga qxl \
    -display default
