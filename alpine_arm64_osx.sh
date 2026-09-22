###############################################################################

# aria2c -x 16 https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/aarch64/alpine-virt-3.24.2-aarch64.iso
aria2c -x 16 https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.24/releases/aarch64/alpine-virt-3.24.2-aarch64.iso
qemu-img create -f qcow2 alpine_arm64.qcow2 20G
# qemu-img resize alpine_arm64.qcow2 100G
qemu-img info alpine_arm64.qcow2

###############################################################################

qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu host \
  -bios edk2-aarch64-code.fd \
  -m 2G \
  -smp 2 \
  -drive file=alpine_arm64.qcow2,format=qcow2,if=virtio \
  -cdrom alpine-virt-3.24.2-aarch64.iso \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic

# root
# nopasswd

# setup-alpine

cat <<'EOF' >auto-install.sh
#!/bin/sh
set -e

cat > /tmp/answerfile << 'ANS'
KEYBOARDOPTS="us us"
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS=""
TIMEZONEOPTS="-z Asia/Shanghai"
PROXYOPTS="none"
APKREPOSOPTS="https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.24/main"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
USEROPTS="none"
DISKOPTS="-m sys /dev/vda"
ANS

export ERASE_DISKS="/dev/vda"
setup-alpine -f /tmp/answerfile
EOF
echo "root:0" | chpasswd
sh auto-install.sh

# poweroff
reboot

###############################################################################

echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.24/community" >>/etc/apk/repositories
apk update

adduser -D -s /bin/ash agi
echo "agi:0" | chpasswd

apk add sudo-rs
addgroup agi wheel
echo "%wheel ALL=(ALL) ALL" >/etc/sudoers
echo "@includedir /etc/sudoers.d" >/etc/sudoers
mkdir -p /etc/sudoers.d
echo "agi ALL=(ALL:ALL) ALL" >/etc/sudoers.d/agi
chmod 0440 /etc/sudoers.d/agi
# test
# su - agi
# sudo whoami
# su - root

mkdir -p /home/agi/.ssh
cat <<'EOF' >/home/agi/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/UyG2mYh9otEF8mf6WX4eAQq4zoRup+/XbAq7W750/ allen@allens-Mac-mini.local
EOF
chmod 700 /home/agi/.ssh
chmod 600 /home/agi/.ssh/authorized_keys
chown -R agi:agi /home/agi/.ssh
mkdir -p /root/.ssh
cat <<'EOF' >/root/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/UyG2mYh9otEF8mf6WX4eAQq4zoRup+/XbAq7W750/ allen@allens-Mac-mini.local
EOF
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
chown -R root:root /root/.ssh

# root
# 0

# ssh -p 2222 agi@127.0.0.1 -i ~/.ssh/id_ed25519
ssh -p 2222 agi@127.0.0.1
# agi
# 0

###############################################################################

# ssh USER@10.0.2.2

###############################################################################

apk update
apk add git

###############################################################################

# later

qemu-system-aarch64 \
  -machine virt,accel=hvf \
  -cpu host \
  -bios edk2-aarch64-code.fd \
  -m 2G \
  -smp 2 \
  -drive file=alpine_arm64.qcow2,format=qcow2,if=virtio \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic

sudo poweroff

ssh -p 2222 agi@127.0.0.1

###############################################################################
