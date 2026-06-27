#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: Post-Build ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

# ── Set default hostname ─────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

# ── Generate ISO config for Titanoboa (bootc-image-builder) ───────────────────
mkdir -p /usr/lib/bootc-image-builder

EDITION=$(echo "$IMAGE_NAME" | sed 's/^bamos-//' | tr '[:lower:]' '[:upper:]')
ISO_LABEL="BAMOS-${EDITION}"

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
mkdir -p /boot/efi/EFI/fedora

for src in \
    "/usr/lib/efi/shim/shimx64.efi" \
    "/usr/lib/efi/shim/mmx64.efi" \
    "/usr/lib/efi/grub/grubx64.efi"; do
  if [ -f "$src" ]; then
    cp -av "$src" /boot/efi/EFI/fedora/
  fi
done

for pkg in shim-x64 grub2-efi-x64; do
  rpm -ql "$pkg" 2>/dev/null | grep '\.efi' | while read -r f; do
    cp -av "$f" /boot/efi/EFI/fedora/ 2>/dev/null || true
  done || true
done

if [ -z "$(ls -A /boot/efi/EFI/fedora/ 2>/dev/null)" ]; then
  find /boot -name '*.efi' -exec cp -av {} /boot/efi/EFI/fedora/ \; 2>/dev/null || true
fi

ls -la /boot/efi/EFI/fedora/ 2>/dev/null || echo "WARNING: No EFI binaries found — ISO may not be bootable"

# ── Rename real dnf5 and create wrappers ──────────────────────────────────────
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
echo "dnf5 wrappers created."

# ── Mark base packages as dependency ──────────────────────────────────────────
echo "Marking base image packages as dependency..."
dnf5.real -y mark dependency $(rpm -qa --qf '%{NAME} ') --skip-unavailable 2>/dev/null || true

# ── Seed overlay state for first-boot ─────────────────────────────────────────
echo "Seeding overlay state for first-boot install..."
DEFAULT_PACKAGES_LIST="/usr/share/bamos/packages.list"
PACKAGES_LIST="/var/lib/bamos/packages.list"
UPPER_DIR="/var/lib/bamos/overlay/upper"
WORK_DIR="/var/lib/bamos/overlay/work"
STATE_FILE="/var/lib/bamos/overlay.state"

mkdir -p /var/lib/bamos
mkdir -p "$UPPER_DIR"
mkdir -p "$WORK_DIR"

# Seed packages.list from default if it exists
if [[ -f "$DEFAULT_PACKAGES_LIST" ]]; then
    cp "$DEFAULT_PACKAGES_LIST" "$PACKAGES_LIST"
    echo "packages.list seeded from defaults."
fi

# Ensure state is absent to trigger full install on first boot
rm -f "$STATE_FILE"
echo "overlay.state cleared — first boot will install packages."

# Ensure packages.list ends with newline
sed -i -e '$a\' /var/lib/bamos/packages.list 2>/dev/null || true

# ── Generate base package manifest ────────────────────────────────────────────
echo "Generating base package manifest..."
/usr/libexec/bamos/bamos-generate-base-manifest

# ── Enable BamOS services ────────────────────────────────────────────────────
echo "Enabling BamOS systemd services..."
systemctl enable bamos-overlay-mount.service
systemctl enable bamos-overlay-sync.service
systemctl enable bamos-overlay-services.service
systemctl enable bamos-base-protect.service
systemctl enable bamos-flatpaks.service
systemctl enable bamos-flatpak-watcher.service
systemctl enable bamos-cache-clean.timer

# Clean up rpm-ostree services from base (we don't use them)
systemctl disable rpm-ostree-clean-metadata.timer 2>/dev/null || true
systemctl disable rpm-ostree-clean-deployments.timer 2>/dev/null || true

echo "=== BamOS: Post-Build Complete ==="
