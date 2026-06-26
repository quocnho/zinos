# Hướng dẫn Build BamOS ISO & Test VM

## Yêu cầu

```bash
# BlueBuild CLI
sudo dnf copr enable xyny/bluebuild
sudo dnf install bluebuild

# Podman
sudo dnf install podman podman-docker

# Công cụ tạo ISO
sudo dnf install lorax-lmc-novirt  # Anaconda live ISO creator

# 15GB+ dung lượng trống cho mỗi lần build
```

---

## 1. Build Image

### Build toàn bộ (đầy đủ packages)

```bash
# Build KDE edition (lần đầu mất ~20-40 phút)
sudo bluebuild build recipes/bamos-kde.yml

# Build GNOME edition
sudo bluebuild build recipes/bamos-gnome.yml

# Build COSMIC edition
sudo bluebuild build recipes/bamos-cosmic.yml
```

### Build nhanh (skip validation nếu cần)

```bash
sudo bluebuild build --skip-validation recipes/bamos-kde.yml
```

### Kiểm tra image đã build

```bash
podman images | grep bamos
```

Output mẫu:
```
localhost/bamos-kde          latest     abc1234   5 phút trước   3.21 GB
localhost/bamos-gnome        latest     def5678   10 phút trước  3.45 GB
```

---

## 2. Generate ISO từ Image đã Build

Dùng `bluebuild generate-iso`:

```bash
# ISO từ image đã build local
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    image ghcr.io/quocnho/bamos-kde:latest

# ISO từ recipe (build + generate cùng lúc)
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    recipe recipes/bamos-kde.yml
```

### Build ISO thủ công (nếu cần tinh chỉnh)

Phương pháp này cho phép chạy `installer/configure-iso.sh` để tuỳ biến:

```bash
# Bước 1: Export image từ local storage
IMAGE_NAME="bamos-kde"
IMAGE_TAG="latest"
sudo podman pull localhost/$IMAGE_NAME:$IMAGE_TAG

# Bước 2: Mount image và chạy configure-iso
CONTAINER=$(sudo podman create localhost/$IMAGE_NAME:$IMAGE_TAG)
sudo podman cp installer $CONTAINER:/tmp/
sudo podman start -a $CONTAINER \
    /tmp/installer/configure-iso.sh
sudo podman commit $CONTAINER $IMAGE_NAME:iso-ready
sudo podman rm $CONTAINER

# Bước 3: Dùng lorax để tạo live ISO
# (Tham khảo: https://github.com/ublue-os/titanoboa)
```

> **Lưu ý:** `bluebuild generate-iso` tự động chạy `configure-iso.sh`. Chỉ cần dùng lệnh trên nếu bạn muốn custom thêm.

---

## 3. Test ISO trong VM

### Test với GNOME Boxes (đơn giản nhất)

```bash
# Cài GNOME Boxes
sudo dnf install gnome-boxes

# Mở Boxes → Chọn ISO → Tạo VM
# Khuyến nghị: 4GB RAM, 2 CPU, 32GB disk
```

### Test với virt-manager (chi tiết hơn)

```bash
# Cài virt-manager
sudo dnf install virt-manager virt-install

# Tạo VM từ ISO
virt-install \
    --name bamos-test \
    --memory 4096 \
    --vcpus 2 \
    --disk size=32 \
    --cdrom ./BamOS-KDE-$(date +%Y%m%d).iso \
    --os-variant fedora-unknown
```

### Test với QEMU command-line

```bash
# Tạo disk image
qemu-img create -f qcow2 bamos-test.qcow2 32G

# Boot từ ISO
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -drive file=bamos-test.qcow2,format=qcow2 \
    -cdrom BamOS-KDE-$(date +%Y%m%d).iso \
    -cpu host \
    -vga virtio
```

---

## 4. Test Image trực tiếp (Container, không cần ISO)

Nhanh hơn nhiều so với ISO:

```bash
# Chạy container từ image
podman run --rm -it \
    --name bamos-test \
    localhost/bamos-kde:latest \
    /bin/bash

# Kiểm tra packages đã cài
rpm -qa | grep -i bamos
cat /etc/os-release

# Kiểm tra kernel
uname -r

# Kiểm tra services
systemctl list-units --type=service | grep bamos
```

### Test với bootc (rebase thật trên máy ảo)

Nếu có VM chạy Fedora Atomic:

```bash
# Trong VM
sudo bootc switch ghcr.io/quocnho/bamos-kde:latest
sudo systemctl reboot

# Kiểm tra
bootc status
cat /etc/os-release
```

---

## 5. Workflow nhanh (Dev loop)

```bash
# 1. Sửa code
vim files/scripts/00-build-setup.sh

# 2. Build nhanh (chỉ rebuild, không push)
sudo bluebuild build recipes/bamos-kde.yml

# 3. Test container
podman run --rm -it localhost/bamos-kde:latest /bin/bash

# 4. Nếu OK, generate ISO
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    image localhost/bamos-kde:latest

# 5. Push lên GitHub
git add -A
git commit -m "fix: update package"
git push origin develop
```

---

## 6. Khắc phục sự cố

### Build chậm / hết dung lượng

```bash
# Dọn cache podman
podman system prune -af

# Kiểm tra dung lượng
df -h /

# Xoá images cũ
podman images | grep bamos | awk '{print $3}' | xargs podman rmi
```

### Lỗi "No space left on device"

```bash
# Xem dung lượng
podman system df

# Xoá cache build
sudo rm -rf /var/lib/containers/storage/vfs-* /var/lib/containers/storage/overlay-* 2>/dev/null || true
```

### Lỗi Anaconda khi generate ISO

```bash
# Cài đủ dependencies
sudo dnf install lorax-lmc-novirt pykickstart

# Kiểm tra kickstart syntax
ksvalidator installer/shared/usr/share/anaconda/post-scripts/install-flatpaks.ks
```
