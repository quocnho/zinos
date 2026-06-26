#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: DE Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

IS_KDE=false
IS_GNOME=false
IS_COSMIC=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true

# RakuOS approach: minimal DE packages
# Base images from ublue (kinoite/silverblue/cosmic) already include DE + GPU support.
# We only need to install missing components and remove bloat.

if [[ "$IS_KDE" == "true" ]]; then
    echo "Installing KDE Plasma packages..."
    # Remove bloat from base kinoite image
    dnf5 -y remove \
        plasma-discover plasma-discover-offline-updates \
        plasma-discover-packagekit plasma-welcome plasma-welcome-fedora \
        firefox firefox-langpacks 2>/dev/null || true
fi

if [[ "$IS_GNOME" == "true" ]]; then
    echo "Installing GNOME packages..."
    # Remove bloat from base silverblue image
    dnf5 -y remove \
        gnome-software-rpm-ostree gnome-tour \
        firefox firefox-langpacks 2>/dev/null || true

    # Compile GSettings schemas (picks up zz-bamos-gnome.gschema.override)
    glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
fi

if [[ "$IS_COSMIC" == "true" ]]; then
    echo "COSMIC edition — using base cosmic-main image."
    dnf5 -y remove firefox firefox-langpacks 2>/dev/null || true
fi

echo "=== BamOS: DE Package Installation Complete ==="
