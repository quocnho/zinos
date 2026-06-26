#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: DE Package Installation ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

IS_KDE=false
IS_GNOME=false
IS_COSMIC=false
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-kde* ]] && IS_KDE=true
[[ "$IMAGE_NAME" == *-gnome* ]] && IS_GNOME=true
[[ "$IMAGE_NAME" == *-cosmic* ]] && IS_COSMIC=true
[[ "$IMAGE_NAME" == *-nvidia* ]] && IS_NVIDIA=true

# ── COSMIC: Install DE packages (since base-main has no DE) ───────────────────
if [[ "$IS_COSMIC" == "true" ]]; then
    echo "Installing COSMIC desktop environment..."

    # Base font & hardware support
    dnf5 -y install @fonts @hardware-support 2>/dev/null || true

    # COSMIC DE packages (from Fedora repos)
    dnf5 -y install \
        cosmic-greeter \
        cosmic-session \
        cosmic-comp \
        cosmic-panel \
        cosmic-settings \
        cosmic-settings-daemon \
        cosmic-wallpapers \
        cosmic-workspaces \
        cosmic-applets \
        cosmic-bg \
        cosmic-launcher \
        cosmic-app-library \
        cosmic-notifications \
        cosmic-idle \
        cosmic-osd \
        cosmic-randr \
        cosmic-icon-theme \
        xdg-desktop-portal-cosmic \
        2>/dev/null || true

    # Enable COSMIC greeter
    systemctl enable cosmic-greeter.service 2>/dev/null || true

    # Add COSMIC Flatpak repo
    flatpak remote-add --if-not-exists cosmic \
        https://apt.pop-os.org/cosmic/cosmic.flatpakrepo 2>/dev/null || true
    echo "COSMIC desktop installed."
fi

# ── GNOME: Compile GSettings ──────────────────────────────────────────────────
if [[ "$IS_GNOME" == "true" ]]; then
    glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
    echo "GSettings schemas compiled for GNOME."
fi

# ── NVIDIA: Reinstall nouveau for compatibility ───────────────────────────────
if [[ "$IS_NVIDIA" == "true" ]]; then
    echo "Preparing NVIDIA system..."
    dnf5 -y reinstall --allowerasing nvidia-gpu-firmware mesa-vulkan-drivers 2>/dev/null || true
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so 2>/dev/null || true
fi

echo "=== BamOS: DE Package Installation Complete ==="
