# BamOS Dev Justfile
# Dùng: just <command> [edition]
# Mặc định edition: kde
# Ví dụ: just build kde-nvidia

registry := "ghcr.io/quocnho"
date := `date +%Y%m%d`
edition := "kde"

# ── BUILD ────────────────────────────────────────────────────────────────────

# Build image: just build [edition]
build edition:
    sudo bluebuild build recipes/bamos-{{edition}}.yml

# Build tất cả 3 editions
build-all:
    @for recipe in recipes/bamos-*.yml; do \
        echo "Building $$(basename $$recipe .yml)..."; \
        sudo bluebuild build "$$recipe"; \
    done
    @echo "All editions built."

# ── TEST ──────────────────────────────────────────────────────────────────────

# Test image in container: just test [edition]
test edition:
    podman run --rm -it "localhost/bamos-{{edition}}:latest" /bin/bash

# ── ISO ───────────────────────────────────────────────────────────────────────

# Generate ISO: just iso [edition]
iso edition:
    sudo bluebuild generate-iso \
        --iso-name "BamOS-{{edition}}-{{date}}.iso" \
        image "localhost/bamos-{{edition}}:latest"

# ── VM ────────────────────────────────────────────────────────────────────────

# Tạo VM từ ISO mới nhất: just vm [edition] [name]
vm edition name:
    sudo virt-install --name "{{name}}" --memory 4096 --vcpus 2 \
        --disk size=32 --cdrom "./BamOS-{{edition}}-{{date}}.iso" \
        --os-variant fedora-unknown &

vm-remove name:
    sudo virsh destroy {{name}} 2>/dev/null || true
    sudo virsh undefine {{name}} --remove-all-storage 2>/dev/null || true

vm-list:
    sudo virsh list --all

# ── DEV LOOP ──────────────────────────────────────────────────────────────────

# Build + ISO: just dev [edition]
dev edition:
    just build {{edition}}
    just iso {{edition}}
    @echo "=== BamOS Dev: {{edition}} built ==="
    @echo "Run: just vm {{edition}} test-vm"

# Build + test container (nhanh nhất)
quick edition:
    just build {{edition}}
    podman run --rm -it "localhost/bamos-{{edition}}:latest" /bin/bash

# ── VALIDATE ──────────────────────────────────────────────────────────────────

# Validate tất cả recipes
validate:
    @for recipe in recipes/bamos-*.yml; do \
        echo -n "$$recipe: "; \
        bluebuild validate "$$recipe" 2>&1 | tail -1; \
    done

# ── CLEANUP ───────────────────────────────────────────────────────────────────

clean-images:
    podman images | grep bamos | awk '{print $3}' | xargs sudo podman rmi -f 2>/dev/null || true

clean-cache:
    podman system prune -af

# ── INFO ──────────────────────────────────────────────────────────────────────

status:
    @echo "=== BamOS Dev ==="
    @echo "bluebuild: $$(bluebuild --version 2>&1 | head -1)"
    @echo "podman: $$(podman --version 2>&1)"
    @echo "just: $$(just --version 2>&1)"
    @echo "KVM: $$( [ -c /dev/kvm ] && echo 'OK' || echo 'MISSING')"
    @echo ""
    @echo "Recipes:"; ls recipes/bamos-*.yml
    @echo ""
    @echo "Commands: just --list"
