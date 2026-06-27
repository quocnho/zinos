#!/usr/bin/env bash
# BamOS: 02-packages.sh — Install core system packages
set -euo pipefail

echo "=== BamOS: Installing Core Packages ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-nvidia ]] && IS_NVIDIA=true

QUALIFIED_KERNEL=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos)

# Swap ffmpeg
dnf5 -y swap ffmpeg ffmpeg-free --allowerasing 2>/dev/null || true

# 32-bit mesa (AMD/Intel only)
if [[ "$IS_NVIDIA" == "false" ]]; then
    dnf5 -y install mesa-dri-drivers.i686 mesa-va-drivers.i686 \
        mesa-vulkan-drivers.i686 mesa-libEGL.i686 mesa-libGL.i686 2>/dev/null || true
fi

# Core packages
dnf5 -y install \
    ananicy-cpp cachyos-ananicy-rules cachyos-settings bore-sysctl \
    scx-scheds scx-tools \
    gamemode gamemode.i686 \
    pulseaudio-utils \
    dkms akmods \
    kernel-cachyos-devel-${QUALIFIED_KERNEL} \
    elfutils-libelf-devel openssl-devel \
    git flatpak libxcrypt-compat rsync \
    podman distrobox mokutil lm_sensors \
    sqlite3 openssl libnotify inotify-tools podman-compose \
    python3-pip python3-setuptools jq \
    appstream appstream-data fwupd \
    fuse squashfuse v4l-utils unzip \
    google-noto-sans-cjk-fonts google-noto-sans-mono-cjk-vf-fonts \
    bibata-cursor-theme adw-gtk3-theme \
    python3-gobject libayatana-appindicator libnotify \
    lv2 lv2-plugin-papowell \
    calf-lv2 \
    jack-audio-connection-kit \
    qjackctl \
    easyeffects

# ── Universal gaming packages (both AMD/Intel and NVIDIA) ─────────────────────
echo "Installing gaming support packages..."
dnf5 -y install \
    mangohud mangohud.i686 \
    vkBasalt vkBasalt.i686 \
    gamescope gamescope-libs gamescope-libs.i686 \
    lutris \
    steam-devices \
    vulkan-tools vulkan-low-latency-layer \
    libFAudio.x86_64 libFAudio.i686 \
    tuned tuned-profiles-atomic \
    input-remapper \
    protontricks \
    2>/dev/null || true

# ── SDL GameControllerDB (game controller mappings) ────────────────────────────
echo "Downloading SDL GameControllerDB..."
mkdir -p /usr/share/sdl
curl -fsSL "https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/master/gamecontrollerdb.txt" \
    -o /usr/share/sdl/gamecontrollerdb.txt 2>/dev/null || echo "SDL GameControllerDB download failed (non-critical)"

# ── Steam autostart desktop config ────────────────────────────────────────────
mkdir -p /etc/skel/.config/autostart
cp /usr/share/applications/steam.desktop /etc/skel/.config/autostart/steam.desktop 2>/dev/null || true

# ── Tuned profiles for gaming power profiles ───────────────────────────────────
mkdir -p /etc/tuned
cat > /etc/tuned/ppd.conf << 'EOF'
# BamOS tuned profiles — gaming optimized
power-saver=powersave
balanced=balanced
performance=throughput-performance
EOF

# EFI/GRUB boot packages
dnf5 -y install \
    grub2-efi-x64 shim-x64 grub2-pc grub2-pc-modules \
    2>/dev/null || true

# Remove unwanted packages (only remove firefox, keep nss — core TLS library)
dnf5 -y remove firefox* 2>/dev/null || true

# Enable Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "=== BamOS: Core Packages Installed ==="
