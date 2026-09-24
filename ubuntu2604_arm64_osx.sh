###############################################################################

aria2c -x 16 https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-arm64.img
cp resolute-server-cloudimg-arm64.img ubuntu2604_arm64.qcow2
qemu-img resize ubuntu2604_arm64.qcow2 100G
qemu-img info ubuntu2604_arm64.qcow2

###############################################################################

# macos
# build cloud-utils

cat >user-data <<EOF
#cloud-config
users:
  - name: agi
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/UyG2mYh9otEF8mf6WX4eAQq4zoRup+/XbAq7W750/ allen@allens-Mac-mini.local
chpasswd:
  list: |
    agi:0
  expire: false
ssh_pwauth: true
EOF
touch meta-data

cloud-localds seed.iso user-data meta-data

###############################################################################

qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu host \
  -bios edk2-aarch64-code.fd \
  -m 2G \
  -smp 2 \
  -drive file=ubuntu2604_arm64.qcow2,format=qcow2,if=virtio \
  -drive file=seed.iso,format=raw,if=virtio,readonly=on \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic

# ssh -p 2222 agi@127.0.0.1 -i ~/.ssh/id_ed25519
ssh -p 2222 agi@127.0.0.1
# agi
# 0

df -h /
lsblk
sudo growpart /dev/vda 1
sudo resize2fs /dev/vda1
df -h /

###############################################################################

# ssh USER@10.0.2.2

###############################################################################

sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
sudo touch /etc/cloud/cloud-init.disabled
sudo systemctl disable snapd.service snapd.socket snapd.seeded.service
sudo systemctl mask snapd.service snapd.socket snapd.seeded.service
sudo systemctl disable snap.lxd.activate.service
sudo systemctl mask snap.lxd.activate.service
# sudo systemctl list-units
sudo systemctl list-unit-files

systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# https://help.mirrors.cernet.edu.cn/ubuntu/
printf '%s' 'Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.ustc.edu.cn/ubuntu
# Suites: resolute resolute-updates resolute-backports
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源为镜像站配置
Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Types: deb-src
# URIs: https://mirrors.ustc.edu.cn/ubuntu
# Suites: resolute-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 预发布软件源，不建议启用

# Types: deb
# URIs: https://mirrors.ustc.edu.cn/ubuntu
# Suites: resolute-proposed
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirrors.ustc.edu.cn/ubuntu
# # Suites: resolute-proposed
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
' | sudo tee /etc/apt/sources.list.d/ubuntu.sources
sudo apt update

###############################################################################

sudo apt update
sudo apt install -y cloud-guest-utils
sudo apt install -y build-essential gcc g++ gdb
sudo apt install -y openssh-server openssh-sftp-server openssh-client
sudo apt install -y sshfs rsync bindfs
sudo apt install -y git
sudo apt install -y htop numactl
sudo apt install -y make

###############################################################################

# later

qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu host \
  -bios edk2-aarch64-code.fd \
  -m 2G \
  -smp 2 \
  -drive file=ubuntu2604_arm64.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic

sudo poweroff

ssh -p 2222 agi@127.0.0.1

###############################################################################
