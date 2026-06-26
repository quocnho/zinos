#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: Build Setup ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"
FEDORA_VERSION=$(rpm -E %fedora)
IS_NVIDIA=false
[[ "$IMAGE_NAME" == *-nvidia ]] && IS_NVIDIA=true

# ── Enable repos ──────────────────────────────────────────────────────────────
dnf5 -y install dnf5-plugins

# RPM Fusion
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm

# CachyOS repos
for copr in bieszczaders/kernel-cachyos bieszczaders/kernel-cachyos-addons; do
    dnf5 -y copr enable "$copr" fedora-${FEDORA_VERSION}-x86_64
done

# Terra repos (for mesa, multimedia)
rpm --import https://repos.fyralabs.com/terra${FEDORA_VERSION}/key.asc 2>/dev/null || true
rpm --import https://repos.fyralabs.com/terra${FEDORA_VERSION}-mesa/key.asc 2>/dev/null || true
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release 2>/dev/null || true
dnf5 -y install --nogpgcheck --repofrompath 'terra-mesa,https://repos.fyralabs.com/terra$releasever' terra-release-mesa 2>/dev/null || true
sed -i '/^priority=/d' /etc/yum.repos.d/terra*.repo 2>/dev/null || true

# ── Remove Fedora kernel ──────────────────────────────────────────────────────
dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core \
    kernel-modules-extra kernel-tools kernel-tools-libs zram-generator-defaults 2>/dev/null || true

# ── Install CachyOS kernel ────────────────────────────────────────────────────
dnf5 -y --setopt=tsflags=noscripts install kernel-cachyos kernel-cachyos-devel-matched

# ── Swap ffmpeg ────────────────────────────────────────────────────────────────
dnf5 -y swap ffmpeg ffmpeg-free --allowerasing 2>/dev/null || true

# ── 32-bit mesa (AMD/Intel only, NVIDIA base already has what's needed) ───────
if [[ "$IS_NVIDIA" == "false" ]]; then
    dnf5 -y install mesa-dri-drivers.i686 mesa-va-drivers.i686 \
        mesa-vulkan-drivers.i686 mesa-libEGL.i686 mesa-libGL.i686 2>/dev/null || true
fi

# ── Install core packages ─────────────────────────────────────────────────────
QUALIFIED_KERNEL=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos)

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
    python3-pip python3-setuptools \
    appstream appstream-data fwupd \
    fuse squashfuse v4l-utils unzip

# ── Remove unwanted packages ──────────────────────────────────────────────────
dnf5 -y remove firefox* nss 2>/dev/null || true

# ── Enable Flathub ────────────────────────────────────────────────────────────
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ── Services ──────────────────────────────────────────────────────────────────
systemctl disable flatpak-add-fedora-repos.service 2>/dev/null || true
systemctl mask akmods-keygen@akmods-keygen.service 2>/dev/null || true

systemctl enable flatpak-cleanup.timer 2>/dev/null || true
systemctl enable rpm-ostree-clean-metadata.timer 2>/dev/null || true
systemctl enable rpm-ostree-clean-deployments.timer 2>/dev/null || true
systemctl enable podman-prune.timer 2>/dev/null || true

# ── NVIDIA setup ──────────────────────────────────────────────────────────────
if [[ "$IS_NVIDIA" == "true" ]]; then
    dnf5 install -y --setopt=tsflags=noscripts dkms-nvidia nvidia-driver nvidia-persistenced 2>/dev/null || true

    NVIDIA_VER=$(rpm -q --queryformat '%{VERSION}\n' dkms-nvidia 2>/dev/null || echo "")
    if [[ -n "$NVIDIA_VER" ]]; then
        LD=ld.bfd dkms install -m nvidia -v "${NVIDIA_VER}" -k "${QUALIFIED_KERNEL}" --force 2>/dev/null || true
    fi

    systemctl enable nvidia-powerd.service 2>/dev/null || true
    systemctl enable nvidia-persistenced.service 2>/dev/null || true
fi

# ── Build initramfs ───────────────────────────────────────────────────────────
depmod "$QUALIFIED_KERNEL" 2>/dev/null || true
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v \
    --add ostree --add fido2 -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img" 2>/dev/null || true
chmod 0600 /usr/lib/modules/"$QUALIFIED_KERNEL"/initramfs.img 2>/dev/null || true

echo "=== BamOS: Build Setup Complete ==="
