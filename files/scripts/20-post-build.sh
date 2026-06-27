#!/usr/bin/env bash
# BamOS: 20-post-build.sh — Final image configuration
set -euo pipefail

echo "=== BamOS: Post-Build ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

# ── Hostname ──────────────────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

# ── ISO config for Titanoboa ──────────────────────────────────────────────────
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

# ── EFI setup ─────────────────────────────────────────────────────────────────
mkdir -p /boot/efi/EFI/fedora
for src in "/usr/lib/efi/shim/shimx64.efi" "/usr/lib/efi/shim/mmx64.efi" "/usr/lib/efi/grub/grubx64.efi"; do
    [[ -f "$src" ]] && cp -av "$src" /boot/efi/EFI/fedora/
done
for pkg in shim-x64 grub2-efi-x64; do
    rpm -ql "$pkg" 2>/dev/null | grep '\.efi' | while read -r f; do
        cp -av "$f" /boot/efi/EFI/fedora/ 2>/dev/null || true
    done || true
done
if [[ -z "$(ls -A /boot/efi/EFI/fedora/ 2>/dev/null)" ]]; then
    find /boot -name '*.efi' -exec cp -av {} /boot/efi/EFI/fedora/ \; 2>/dev/null || true
fi

# ── dnf5 wrappers ─────────────────────────────────────────────────────────────
mv /usr/bin/dnf5 /usr/bin/dnf5.real 2>/dev/null || true
mv /usr/bin/dnf /usr/bin/dnf.real 2>/dev/null || true

cat > /usr/bin/dnf5 << 'WRAPPER'
#!/usr/bin/env bash
case "${1:-}" in
    install) shift; exec bamos install "$@" ;;
    update|upgrade) shift; exec bamos update "$@" ;;
    remove|erase) shift; exec bamos remove "$@" ;;
    *) exec /usr/bin/dnf5.real "$@" ;;
esac
WRAPPER
cat > /usr/bin/dnf << 'WRAPPER'
#!/usr/bin/env bash
exec /usr/bin/dnf5 "$@"
WRAPPER
chmod +x /usr/bin/dnf5 /usr/bin/dnf

# Mark base packages as dependency (prevents accidental removal)
echo "Marking base packages as dependency (prevents accidental removal)..."
rpm -qa --qf '%{NAME}\n' | xargs -r dnf5.real -y mark install --skip-unavailable 2>/dev/null || true

# ── Seed overlay for first-boot ───────────────────────────────────────────────
echo "Seeding overlay state for first-boot..."
mkdir -p /var/lib/bamos /var/lib/bamos/overlay/{upper,work}

DEFAULT_PACKAGES_LIST="/usr/share/bamos/packages.list"
if [[ -f "$DEFAULT_PACKAGES_LIST" ]]; then
    cp "$DEFAULT_PACKAGES_LIST" /var/lib/bamos/packages.list
fi

# Record pre-installed gaming/studio packages so bamos list shows them
# These are already baked into the image, but tracking them helps users
for pkg in mangohud vkBasalt gamescope lutris steam-devices vulkan-tools \
    vulkan-low-latency-layer libFAudio tuned input-remapper protontricks; do
    if ! grep -qxF "$pkg" /var/lib/bamos/packages.list 2>/dev/null; then
        echo "$pkg" >> /var/lib/bamos/packages.list
    fi
done
sed -i -e '$a\' /var/lib/bamos/packages.list 2>/dev/null || true

# Remove state file to trigger first-boot install
rm -f /var/lib/bamos/overlay.state
rm -f /var/lib/bamos/setup-done

# ── Generate base manifest ────────────────────────────────────────────────────
/usr/libexec/bamos/bamos-generate-base-manifest

# ── Set Plymouth default theme ────────────────────────────────────────────────
echo "Setting Plymouth theme..."
if plymouth-set-default-theme bamos 2>/dev/null; then
    echo "Plymouth theme: bamos"
else
    plymouth-set-default-theme spinner 2>/dev/null || true
    echo "Plymouth theme: spinner (bamos theme not found)"
fi

# ── Enable systemd services ───────────────────────────────────────────────────
echo "Enabling BamOS systemd services..."
systemctl enable bamos-firstboot.service
systemctl enable bamos-overlay-mount.service
systemctl disable rpm-ostree-clean-metadata.timer 2>/dev/null || true
systemctl disable rpm-ostree-clean-deployments.timer 2>/dev/null || true

echo "=== BamOS: Post-Build Complete ==="
