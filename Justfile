# BamOS Dev Justfile
# Dùng: just <command>
# Xem all commands: just --list

registry := "ghcr.io/quocnho"
date := `date +%Y%m%d`

# ── BUILD ────────────────────────────────────────────────────────────────────

# Build KDE edition
build-kde:
    sudo bluebuild build recipes/bamos-kde.yml

# Build KDE NVIDIA edition
build-kde-nvidia:
    sudo bluebuild build recipes/bamos-kde-nvidia.yml

# Build GNOME edition
build-gnome:
    sudo bluebuild build recipes/bamos-gnome.yml

# Build GNOME NVIDIA edition
build-gnome-nvidia:
    sudo bluebuild build recipes/bamos-gnome-nvidia.yml

# Build COSMIC edition
build-cosmic:
    sudo bluebuild build recipes/bamos-cosmic.yml

# Build COSMIC NVIDIA edition
build-cosmic-nvidia:
    sudo bluebuild build recipes/bamos-cosmic-nvidia.yml

# Build ALL 6 editions
build-all: build-kde build-kde-nvidia build-gnome build-gnome-nvidia build-cosmic build-cosmic-nvidia

# ── TEST CONTAINER ────────────────────────────────────────────────────────────

# Test KDE trong container
test-kde:
    podman run --rm -it localhost/bamos-kde:latest /bin/bash

# Test GNOME trong container
test-gnome:
    podman run --rm -it localhost/bamos-gnome:latest /bin/bash

# Test COSMIC trong container
test-cosmic:
    podman run --rm -it localhost/bamos-cosmic:latest /bin/bash

# ── ISO ───────────────────────────────────────────────────────────────────────

# Generate ISO cho KDE (AMD/Intel)
iso-kde:
    sudo bluebuild generate-iso --iso-name "BamOS-KDE-{{date}}.iso" image localhost/bamos-kde:latest

# Generate ISO cho KDE NVIDIA
iso-kde-nvidia:
    sudo bluebuild generate-iso --iso-name "BamOS-KDE-NVIDIA-{{date}}.iso" image localhost/bamos-kde-nvidia:latest

# Generate ISO cho GNOME (AMD/Intel)
iso-gnome:
    sudo bluebuild generate-iso --iso-name "BamOS-GNOME-{{date}}.iso" image localhost/bamos-gnome:latest

# Generate ISO cho GNOME NVIDIA
iso-gnome-nvidia:
    sudo bluebuild generate-iso --iso-name "BamOS-GNOME-NVIDIA-{{date}}.iso" image localhost/bamos-gnome-nvidia:latest

# Generate ISO cho COSMIC (AMD/Intel)
iso-cosmic:
    sudo bluebuild generate-iso --iso-name "BamOS-COSMIC-{{date}}.iso" image localhost/bamos-cosmic:latest

# Generate ISO cho COSMIC NVIDIA
iso-cosmic-nvidia:
    sudo bluebuild generate-iso --iso-name "BamOS-COSMIC-NVIDIA-{{date}}.iso" image localhost/bamos-cosmic-nvidia:latest

# ── VM ────────────────────────────────────────────────────────────────────────

# Tạo VM KDE từ ISO mới nhất
vm-kde: iso-kde
    sudo virt-install --name bamos-kde --memory 4096 --vcpus 2 \
        --disk size=32 --cdrom BamOS-KDE-{{date}}.iso \
        --os-variant fedora-unknown &

# Tạo VM GNOME từ ISO mới nhất
vm-gnome: iso-gnome
    sudo virt-install --name bamos-gnome --memory 4096 --vcpus 2 \
        --disk size=32 --cdrom BamOS-GNOME-{{date}}.iso \
        --os-variant fedora-unknown &

# Tạo VM COSMIC từ ISO mới nhất
vm-cosmic: iso-cosmic
    sudo virt-install --name bamos-cosmic --memory 4096 --vcpus 2 \
        --disk size=32 --cdrom BamOS-COSMIC-{{date}}.iso \
        --os-variant fedora-unknown &

# Xoá VM (dùng: just vm-remove <name>)
vm-remove name:
    sudo virsh destroy {{name}} 2>/dev/null || true
    sudo virsh undefine {{name}} --remove-all-storage 2>/dev/null || true
    @echo "VM '{{name}}' đã xoá."

# List tất cả VM
vm-list:
    sudo virsh list --all

# ── DEV LOOP ──────────────────────────────────────────────────────────────────

# Dev loop: build KDE → test container → ISO → VM
dev-kde: build-kde iso-kde
    @echo "=== BamOS Dev Loop Complete ==="
    @echo "Image built. ISO generated."
    @echo "Run: just vm-kde  (tạo VM)"
    @echo "Run: podman run --rm -it localhost/bamos-kde:latest /bin/bash  (test container)"

# Dev loop: build GNOME → test container → ISO → VM
dev-gnome: build-gnome iso-gnome
    @echo "=== BamOS Dev Loop Complete ==="

# Quick: build + test container (nhanh nhất, không ISO)
quick-kde: build-kde
    podman run --rm -it localhost/bamos-kde:latest /bin/bash

quick-gnome: build-gnome
    podman run --rm -it localhost/bamos-gnome:latest /bin/bash

# ── VALIDATE ──────────────────────────────────────────────────────────────────

# Validate tất cả recipes
validate:
    @for recipe in recipes/bamos-*.yml; do \
        echo -n "$$recipe: "; \
        bluebuild validate "$$recipe" 2>&1 | tail -1; \
    done

# ── CLEANUP ───────────────────────────────────────────────────────────────────

# Xoá tất cả images BamOS local
clean-images:
    podman images | grep bamos | awk '{print $3}' | xargs sudo podman rmi -f 2>/dev/null || true
    @echo "Đã xoá images BamOS."

# Dọn cache podman
clean-cache:
    podman system prune -af
    @echo "Đã dọn cache."

# ── INFO ──────────────────────────────────────────────────────────────────────

# Hiển thị trạng thái hệ thống
status:
    @echo "=== BamOS Dev Environment ==="
    @echo "bluebuild: $$(bluebuild --version 2>&1 | head -1)"
    @echo "podman: $$(podman --version 2>&1)"
    @echo "just: $$(just --version 2>&1)"
    @echo "KVM: $$( [ -c /dev/kvm ] && echo 'OK' || echo 'MISSING')"
    @echo "libvirtd: $$(systemctl is-active libvirtd 2>/dev/null || echo 'inactive')"
    @echo ""
    @echo "Images:"
    @podman images | grep -E 'bamos|ghcr.io' || echo "  (none)"
    @echo ""
    @echo "Commands: just --list"
