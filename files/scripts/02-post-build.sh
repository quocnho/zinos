#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: Post-Build ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

# ── Set default hostname ─────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

# ── Generate ISO config for Titanoboa (bootc-image-builder) ───────────────────
# This file is required by ublue-os/titanoboa to generate bootable ISOs
mkdir -p /usr/lib/bootc-image-builder

# Derive edition name from IMAGE_NAME (e.g. bamos-kde-nvidia → KDE-NVIDIA)
EDITION=$(echo "$IMAGE_NAME" | sed 's/^bamos-//' | tr '[:lower:]' '[:upper:]')
ISO_LABEL="BAMOS-${EDITION}"

# Map IMAGE_NAME to human-readable display name
case "$IMAGE_NAME" in
    *-kde-nvidia*)    DISPLAY="BamOS KDE Plasma (NVIDIA)" ;;
    *-kde*)           DISPLAY="BamOS KDE Plasma" ;;
    *-gnome-nvidia*)  DISPLAY="BamOS GNOME (NVIDIA)" ;;
    *-gnome*)         DISPLAY="BamOS GNOME" ;;
    *-cosmic-nvidia*) DISPLAY="BamOS COSMIC (NVIDIA)" ;;
    *-cosmic*)        DISPLAY="BamOS COSMIC" ;;
    *)                DISPLAY="BamOS Linux" ;;
esac

cat > /usr/lib/bootc-image-builder/iso.yaml << EOF
label: ${ISO_LABEL}
grub2:
  default: 0
  timeout: 10
  entries:
    - name: "${DISPLAY} Live"
      linux: "/images/pxeboot/vmlinuz quiet rhgb root=live:CDLABEL=${ISO_LABEL} enforcing=0 rd.live.image"
      initrd: "/images/pxeboot/initrd.img"
    - name: "${DISPLAY} Live (Basic Graphics)"
      linux: "/images/pxeboot/vmlinuz quiet rhgb root=live:CDLABEL=${ISO_LABEL} enforcing=0 rd.live.image nomodeset"
      initrd: "/images/pxeboot/initrd.img"
EOF
echo "Generated /usr/lib/bootc-image-builder/iso.yaml for ${DISPLAY} (label: ${ISO_LABEL})"

# ── Setup EFI directory for Titanoboa ISO generation ─────────────────────────
# Titanoboa's build_iso.sh expects /boot/efi/EFI with shim + grub EFI binaries.
# In container builds, this dir may not be auto-created by packages.
mkdir -p /boot/efi/EFI/fedora

# Find and copy EFI binaries from RPM-installed locations
for src in \
    "/usr/lib/efi/shim/shimx64.efi" \
    "/usr/lib/efi/shim/mmx64.efi" \
    "/usr/lib/efi/grub/grubx64.efi"; do
  if [ -f "$src" ]; then
    cp -av "$src" /boot/efi/EFI/fedora/
  fi
done

# Try rpm -ql as fallback to find EFI files
for pkg in shim-x64 grub2-efi-x64; do
  rpm -ql "$pkg" 2>/dev/null | grep '\.efi' | while read -r f; do
    cp -av "$f" /boot/efi/EFI/fedora/ 2>/dev/null || true
  done || true
done

# If still empty, copy from /boot as fallback
if [ -z "$(ls -A /boot/efi/EFI/fedora/ 2>/dev/null)" ]; then
  find /boot -name '*.efi' -exec cp -av {} /boot/efi/EFI/fedora/ \; 2>/dev/null || true
fi

ls -la /boot/efi/EFI/fedora/ 2>/dev/null || echo "WARNING: No EFI binaries found — ISO may not be bootable"

# ── Rename real dnf5 and create wrappers (like RakuOS) ──────────────────────
# Only create wrappers for installed system (not during container build)
if ! findmnt /usr | grep -q overlay; then
    mv /usr/bin/dnf5 /usr/bin/dnf5.real 2>/dev/null || true
    mv /usr/bin/dnf /usr/bin/dnf.real 2>/dev/null || true

    # Create dnf5 wrapper that routes install/remove/update through bamos
    cat > /usr/bin/dnf5 << 'WRAPPER'
#!/usr/bin/env bash
COMMAND="${1:-}"
case "$COMMAND" in
    install)
        shift
        exec bamos install "$@"
        ;;
    update|upgrade)
        shift
        exec bamos update "$@"
        ;;
    remove|erase)
        shift
        exec bamos remove "$@"
        ;;
    *)
        exec /usr/bin/dnf5.real "$@"
        ;;
esac
WRAPPER

    # Create dnf wrapper
    cat > /usr/bin/dnf << 'WRAPPER'
#!/usr/bin/env bash
exec /usr/bin/dnf5 "$@"
WRAPPER

    chmod +x /usr/bin/dnf5 /usr/bin/dnf
    echo "dnf5 wrappers created (installed system detected)."
else
    echo "Container build detected — skipping dnf5 wrappers."
fi

echo "=== BamOS: Post-Build Complete ==="
