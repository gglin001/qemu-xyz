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

setup-alpine

###############################################################################
