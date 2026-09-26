###############################################################################

aria2c -x 16 https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-arm64.img
qemu-img convert -f qcow2 -O raw resolute-server-cloudimg-arm64.img ubuntu2604_arm64_vfkit.raw
qemu-img resize -f raw ubuntu2604_arm64_vfkit.raw 100G
qemu-img info ubuntu2604_arm64_vfkit.raw

###############################################################################

# macos
# build cloud-utils

cat >vfkit-user-data <<EOF
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
    root:0
  expire: false
ssh_pwauth: true
runcmd:
  - [systemctl, enable, --now, serial-getty@hvc0.service]
EOF
cat >vfkit-meta-data <<EOF
instance-id: ubuntu-vfkit
local-hostname: ubuntu
EOF

# use the MAC as the DHCP identifier so the macos lease lookup stays consistent
cat >vfkit-network-config <<EOF
version: 2
ethernets:
  vfkit:
    match:
      macaddress: '52:54:26:aa:bb:cc'
    dhcp4: true
    dhcp-identifier: mac
EOF

cloud-localds --network-config=vfkit-network-config vfkit-seed.iso vfkit-user-data vfkit-meta-data

###############################################################################

# first boot, wait for cloud-init to enable the hvc0 login console
# keep this terminal open, use another macos terminal for ssh

vfkit \
  --cpus 2 \
  --memory 2048 \
  --bootloader efi,variable-store=vfkit-efi,create \
  --device virtio-blk,path=ubuntu2604_arm64_vfkit.raw \
  --device virtio-blk,path=vfkit-seed.iso,readonly \
  --device virtio-net,nat,mac=52:54:26:aa:bb:cc \
  --device virtio-rng \
  --device virtio-serial,stdio

# macos, find the VM address from its fixed MAC after DHCP completes
VM_IP=$(awk 'BEGIN { RS="}" } /hw_address=1,52:54:26:aa:bb:cc/ { for (i=1; i<=NF; i++) if ($i ~ /^ip_address=/) { sub(/^ip_address=/, "", $i); print $i; exit } }' /var/db/dhcpd_leases)
ssh agi@"$VM_IP"

###############################################################################

# inside the VM

sudo cloud-init status --wait
df -h /
lsblk
# cloud-init normally grows the root partition automatically
# sudo growpart /dev/vda 1
# sudo resize2fs /dev/vda1

sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
sudo touch /etc/cloud/cloud-init.disabled
sudo systemctl disable snapd.service snapd.socket snapd.seeded.service
sudo systemctl mask snapd.service snapd.socket snapd.seeded.service
sudo systemctl disable snap.lxd.activate.service
sudo systemctl mask snap.lxd.activate.service
# sudo systemctl list-units
# sudo systemctl list-unit-files

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

vfkit \
  --cpus 2 \
  --memory 2048 \
  --bootloader efi,variable-store=vfkit-efi \
  --device virtio-blk,path=ubuntu2604_arm64_vfkit.raw \
  --device virtio-net,nat,mac=52:54:26:aa:bb:cc \
  --device virtio-rng \
  --device virtio-serial,stdio

# macos, another terminal
VM_IP=$(awk 'BEGIN { RS="}" } /hw_address=1,52:54:26:aa:bb:cc/ { for (i=1; i<=NF; i++) if ($i ~ /^ip_address=/) { sub(/^ip_address=/, "", $i); print $i; exit } }' /var/db/dhcpd_leases)
ssh agi@"$VM_IP"

# inside the VM
sudo poweroff

###############################################################################
