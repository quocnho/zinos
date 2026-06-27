#!/usr/bin/env bash
# BamOS: 10-de-packages.sh — Desktop Environment package installation
set -euo pipefail

echo "=== BamOS: DE Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

IS_KDE=false; IS_GNOME=false; IS_COSMIC=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true

# ── COSMIC ─────────────────────────────────────────────────────────────────────
if [[ "$IS_COSMIC" == "true" ]]; then
    echo "Installing COSMIC desktop..."

    dnf5 -y install @fonts @hardware-support 2>/dev/null || true

    # COSMIC DE — try cosmic-epoch packages first (Fedora 44+), fallback to cosmic-
    if dnf5 -y install \
        cosmic-epoch-greeter cosmic-epoch-session cosmic-epoch-comp \
        cosmic-epoch-panel cosmic-epoch-settings cosmic-epoch-settings-daemon \
        cosmic-epoch-wallpapers cosmic-epoch-workspaces cosmic-epoch-applets \
        cosmic-epoch-bg cosmic-epoch-launcher cosmic-epoch-app-library \
        cosmic-epoch-notifications cosmic-epoch-idle cosmic-epoch-osd \
        cosmic-epoch-randr cosmic-epoch-icon-theme xdg-desktop-portal-cosmic \
        2>/dev/null; then
        GREETER="cosmic-epoch-greeter.service"
    else
        dnf5 -y install \
            cosmic-greeter cosmic-session cosmic-comp cosmic-panel \
            cosmic-settings cosmic-settings-daemon cosmic-wallpapers \
            cosmic-workspaces cosmic-applets cosmic-bg cosmic-launcher \
            cosmic-app-library cosmic-notifications cosmic-idle cosmic-osd \
            cosmic-randr cosmic-icon-theme xdg-desktop-portal-cosmic \
            2>/dev/null || true
        GREETER="cosmic-greeter.service"
    fi

    systemctl enable "$GREETER" 2>/dev/null || true

    # COSMIC Flatpak repo
    flatpak remote-add --if-not-exists cosmic \
        https://apt.pop-os.org/cosmic/cosmic.flatpakrepo 2>/dev/null || true
    flatpak install -y --noninteractive cosmic \
        com.system76.CosmicStore com.system76.CosmicTerminal \
        com.system76.CosmicFiles com.system76.CosmicSettings \
        com.system76.CosmicAppLibrary 2>/dev/null || true
fi

# ── KDE ────────────────────────────────────────────────────────────────────────
if [[ "$IS_KDE" == "true" ]]; then
    echo "Configuring KDE Plasma..."
    # Remove unwanted KDE packages via dnf5
    dnf5 -y remove plasma-discover plasma-discover-offline-updates \
        plasma-discover-packagekit plasma-welcome plasma-welcome-fedora 2>/dev/null || true
fi

# ── GNOME ──────────────────────────────────────────────────────────────────────
if [[ "$IS_GNOME" == "true" ]]; then
    echo "Configuring GNOME..."
    dnf5 -y remove gnome-software-rpm-ostree gnome-tour 2>/dev/null || true
    glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
fi

echo "=== BamOS: DE Package Installation Complete ==="
