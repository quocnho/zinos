# Hướng dẫn Build BamOS ISO & Test VM

> ⚠️ **Môi trường hiện tại**: Laptop chạy **RakuOS** (Fedora Atomic / bootc-based)
> — immutable OS, cài package qua `rakuos install` (overlay) hoặc `rpm-ostree install` (layer).
> Công cụ VM đã được cài sẵn (xem mục 0).

---

## 0. Môi trường đã có sẵn

| Công cụ | Trạng thái | Ghi chú |
|---------|-----------|---------|
| `bluebuild` CLI | ✅ Đã cài | `/usr/local/bin/bluebuild` |
| `podman` | ✅ Có sẵn | Base image |
| `qemu-kvm` | ✅ Đã cài | Qua `rakuos install` |
| `virt-manager` | ✅ Đã cài | GUI tạo VM |
| `virt-install` | ✅ Đã cài | CLI tạo VM |
| `gnome-boxes` | ✅ Đã cài | GUI đơn giản |
| KVM acceleration | ✅ Intel VT-x | `/dev/kvm` available |
| `libvirtd` | ✅ Đã enable | `sudo systemctl enable --now libvirtd` |
| Default network | ✅ Đã autostart | `virsh net-autostart default` |
| Disk space | ~459 GB trên `/var` | Cho VM images |

> **Lưu ý**: Re-login sau khi thêm vào nhóm `libvirt`:
> ```bash
> newgrp libvirt
> ```

### Cài thêm công cụ nếu thiếu

```bash
# Trên RakuOS (immutable) — dùng rakuos install
sudo rakuos install qemu-kvm virt-manager virt-install gnome-boxes
```

---

## 1. Build Image (Local)

```bash
cd ~/Projects/bamos

# Build KDE edition (lần đầu ~20-40 phút)
sudo bluebuild build recipes/bamos-kde.yml

# Build nhanh (skip validation)
sudo bluebuild build --skip-validation recipes/bamos-kde.yml

# Kiểm tra
podman images | grep bamos
```

---

## 2. Build Image + ISO (CI — GitHub Actions)

Khi push lên `main`, CI tự động:

```
1. Build-images: Build 6 images + push lên GHCR (matrix, song song)
       ↓
2. Build-isos: Generate 6 ISOs từ images (tuần tự, 1 cái 1 lần)
       ↓
3. Release: Upload 6 ISOs lên GitHub Releases (nightly)
```

**Trigger ISO trên `main`:**
```bash
git checkout main
git merge develop
git push origin main
# → CI tự động build images + generate ISOs + release
```

**Trigger ISO thủ công (bất kỳ branch):**
```
Vào: github.com/quocnho/bamos/actions
→ Workflow: Build BamOS
→ Run workflow → Check "Generate ISOs"
```

**Tải ISO từ GitHub Releases:**
```
Vào: github.com/quocnho/bamos/releases
→ Chọn "BamOS Nightly" mới nhất
→ Tải file .iso mong muốn
```

---

## 3. Generate ISO Local (nếu muốn test trước khi push)

```bash
# Build image trước
sudo bluebuild build recipes/bamos-kde.yml

# Generate ISO từ image local
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    image localhost/bamos-kde:latest
```

---

## 4. Test ISO trong VM

### GNOME Boxes (đơn giản)
```bash
gnome-boxes &
```

### virt-manager (chi tiết)
```bash
virt-manager &
```

### virt-install (CLI)
```bash
sudo virt-install \
    --name bamos-test \
    --memory 4096 \
    --vcpus 2 \
    --disk size=32 \
    --cdrom ./BamOS-KDE-*.iso \
    --os-variant fedora-unknown
```

---

## 5. Dev Loop nhanh

```bash
# Build + test container (nhanh nhất, không ISO)
just quick-gnome

# Build + ISO
just dev-gnome

# Validate recipes
just validate

# Xem trạng thái
just status
```

---

## 6. Khắc phục sự cố

```bash
# Dọn cache
podman system prune -af

# Xoá VM cũ
sudo virsh destroy bamos-test 2>/dev/null || true
sudo virsh undefine bamos-test --remove-all-storage 2>/dev/null || true

# Xoá images cũ
podman images | grep bamos | awk '{print $3}' | xargs sudo podman rmi -f
```
