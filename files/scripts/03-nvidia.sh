#!/usr/bin/env bash
# BamOS: 03-nvidia.sh — NVIDIA driver + DKMS + initramfs
set -euo pipefail

echo "=== BamOS: NVIDIA & Initramfs Setup ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-nvidia ]] && IS_NVIDIA=true

QUALIFIED_KERNEL=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos)

# ── NVIDIA driver ──────────────────────────────────────────────────────────────
if [[ "$IS_NVIDIA" == "true" ]]; then
    echo "Installing NVIDIA drivers..."
    dnf5 -y install --setopt=tsflags=noscripts dkms-nvidia nvidia-driver nvidia-persistenced 2>/dev/null || true

    NVIDIA_VER=$(rpm -q --queryformat '%{VERSION}\n' dkms-nvidia 2>/dev/null || echo "")
    if [[ -n "$NVIDIA_VER" ]]; then
        LD=ld.bfd dkms install -m nvidia -v "${NVIDIA_VER}" -k "${QUALIFIED_KERNEL}" --force 2>/dev/null || true
    fi

    systemctl enable nvidia-powerd.service 2>/dev/null || true
    systemctl enable nvidia-persistenced.service 2>/dev/null || true

    # NVIDIA udev rules (for module auto-loading)
    mkdir -p /etc/udev/rules.d
    cat > /etc/udev/rules.d/80-nvidia-pm.rules << 'EOF'
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/sbin/modprobe nvidia-drm"
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/sbin/modprobe nvidia-uvm"
EOF

    # NVIDIA suspend/resume support (nvidia-sleep.sh is installed by nvidia-driver package on target)
    cat > /etc/systemd/system/nvidia-suspend.service << 'EOF'
[Unit]
Description=NVIDIA system suspend/resume
Before=systemd-suspend.service
ConditionFileNotEmpty=/usr/bin/nvidia-sleep.sh
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/nvidia-sleep.sh suspend
ExecStop=/usr/bin/nvidia-sleep.sh resume
[Install]
WantedBy=systemd-suspend.service
EOF

    # NVIDIA dracut config (must be in place BEFORE initramfs build below)
    mkdir -p /usr/lib/dracut/dracut.conf.d
    cat > /usr/lib/dracut/dracut.conf.d/nvidia-bamos.conf << 'EOF'
# Include NVIDIA kernel modules in initramfs
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
EOF

    # NVIDIA modprobe config
    mkdir -p /etc/modprobe.d
    cat > /etc/modprobe.d/nvidia-modeset.conf << 'EOF'
# Force nvidia_drm modeset + fbdev for Wayland support
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_EnableMSI=1
options nvidia NVreg_OpenRmEnableUnsupportedGpus=1
EOF

    # NVIDIA environment variables
    mkdir -p /etc/environment.d
    cat > /etc/environment.d/10-nvidia.conf << 'NVEOF'
# NVIDIA Wayland & GTK fixes
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
WLR_NO_HARDWARE_CURSORS=1
# GSK_RENDERER=vulkan is preferred on driver 545+; use 'gl' fallback if needed
NVEOF

    # Reinstall mesa for NVIDIA compatibility
    dnf5 -y reinstall --allowerasing nvidia-gpu-firmware mesa-vulkan-drivers 2>/dev/null || true
    ln -sf /usr/lib64/libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so 2>/dev/null || true

    # ── NVIDIA-specific gaming packages ─────────────────────────────────────────
    echo "Installing NVIDIA deep gaming packages..."
    dnf5 -y install \
        dkms-xpadneo \
        dkms-xone xone-firmware \
        openxr \
        obs-studio-plugin-vkcapture-hook-libs.i686 \
        umu-launcher \
        2>/dev/null || true

    # ── OBS NVIDIA encoding ───────────────────────────────────────────────────
    # Enable NVENC via environment variable for OBS
    mkdir -p /etc/environment.d
    cat > /etc/environment.d/10-nvidia-obs.conf << 'NVEOF'
# NVIDIA OBS Studio — NVENC hardware encoding
OBS_USE_NVENC=1
NVEOF

    # ── NVIDIA Gamescope config ───────────────────────────────────────────────
    mkdir -p /etc/gamescope
    cat > /etc/gamescope/nvidia.conf << 'EOF'
# BamOS Gamescope NVIDIA configuration
# Gamescope fixes for NVIDIA: adaptive sync, latency reduction
# https://github.com/ValveSoftware/gamescope

# NVIDIA-specific flags
--adaptive-sync
--backend vulkan
EOF

    # ── DXVK configuration for Proton ─────────────────────────────────────────
    curl -fsSL "https://raw.githubusercontent.com/doitsujin/dxvk/master/dxvk.conf" \
        -o /etc/dxvk.conf 2>/dev/null || true
fi

# ── BORE scheduler sysctl tuning (both NVIDIA and non-NVIDIA) ──────────────────
echo "Configuring BORE CPU scheduler..."
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/90-bore.conf << 'EOF'
# BORE scheduler: prefer lower latency over throughput
# Higher values = more aggressive boost to sleeping tasks (better for gaming)
kernel.sched_bore = 1
kernel.sched_child_runs_first = 1
EOF

# ── Build initramfs ────────────────────────────────────────────────────────────
echo "Building initramfs for kernel ${QUALIFIED_KERNEL}..."
depmod "$QUALIFIED_KERNEL" 2>/dev/null || true
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v \
    --add ostree --add fido2 -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img" 2>/dev/null || true
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img 2>/dev/null || true

echo "=== BamOS: NVIDIA & Initramfs Complete ==="
