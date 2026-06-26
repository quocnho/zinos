#!/usr/bin/env bash
set -ouex pipefail

# BamOS Flatpak Catalog Module
# Installs Bazaar Flatpak manager and configures with BamOS catalog

echo "=== BamOS: Bazaar Flatpak Catalog ==="

# Install bazaar from COPR
dnf5 -y install bazaar 2>/dev/null || {
    echo "Bazaar not available — enabling required COPR repos..."
    dnf5 -y copr enable ublue-os/bazzite 2>/dev/null || true
    dnf5 -y copr enable ublue-os/packages 2>/dev/null || true
    dnf5 -y install bazaar 2>/dev/null || echo "Warning: Could not install bazaar"
}

# Copy BamOS bazaar catalog
if [[ -d /tmp/bamos-bazaar ]]; then
    mkdir -p /usr/share/ublue-os/bazaar
    cp -af /tmp/bamos-bazaar/. /usr/share/ublue-os/bazaar/
    echo "BamOS Bazaar catalog installed."
fi

echo "=== BamOS: Bazaar Flatpak Catalog Complete ==="
