#!/usr/bin/env bash
set -exo pipefail

source /etc/os-release

echo "=== BamOS: ISO Configuration ==="

# ── Remove versionlocks ──────────────────────────────────────────────────────
dnf -qy versionlock clear 2>/dev/null || true

# ── Install Anaconda & live dependencies ──────────────────────────────────────
dnf install -qy --enable-repo=fedora-cisco-openh264 --allowerasing \
    anaconda-live libblockdev-{btrfs,lvm,dm} 2>/dev/null || true

mkdir -p /var/lib/rpm-state

# ── Install utilities for installer dialogs ──────────────────────────────────
dnf install -qy --setopt=install_weak_deps=0 qrencode yad 2>/dev/null || true

# ── Detect image reference ───────────────────────────────────────────────────
imageref="$(podman images --format '{{ index .Names 0 }}\n' 'bamos*' | head -1)"
imageref="${imageref##*://}"
imageref="${imageref%%:*}"
imagetag="$(podman images --format '{{ .Tag }}\n' "$imageref" | head -1)"

# ── Set OS release for installer ──────────────────────────────────────────────
: ${VARIANT_ID:?}
echo "BamOS release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

# ── Detect desktop environment ────────────────────────────────────────────────
desktop_env=""
_session_file="$(find /usr/share/wayland-sessions/ /usr/share/xsessions \
    -maxdepth 1 -type f -not -name '*gamescope*.desktop' -and -name '*.desktop' -printf '%P' -quit 2>/dev/null)"
case $_session_file in
    cosmic*) desktop_env=cosmic ;;
    gnome*)  desktop_env=gnome ;;
    plasma*) desktop_env=kde ;;
    *)       desktop_env=unknown ;;
esac
echo "Detected desktop environment: $desktop_env"

# ── Anaconda profile config ──────────────────────────────────────────────────
mkdir -p /etc/anaconda/profile.d
cat > /etc/anaconda/profile.d/bamos.conf << 'BAMOS_PROFILE'
# BamOS Anaconda profile
anaconda_profile=bamos
BAMOS_PROFILE

# ── Default Kickstart ────────────────────────────────────────────────────────
cat <<EOF >>/usr/share/anaconda/interactive-defaults.ks

# Create log directory
%pre
mkdir -p /tmp/anaconda_custom_logs
%end

# Check if there is a bitlocker partition and ask the user to disable it
%pre --erroronfail --log=/tmp/anaconda_custom_logs/detect_bitlocker.log
DOCS_QR=/tmp/detect_bitlocker_qr.png
IS_BITLOCKER=\$(lsblk -o FSTYPE --json | jq '.blockdevices | map(select(.fstype == "BitLocker")) | . != []')
{ WARNING_MSG="\$(</dev/stdin)"; } << 'WARNINGEOF'
<span size="x-large">Windows Bitlocker partition detected</span>

It might interrupt the installation process.
In such case, please, do <b>one</b> of the following:
    a) Disconnect its storage drive.
    b) Disable Bitlocker in Windows.
    c) Delete it in GNOME Disks.

Do you wish to continue?
WARNINGEOF

if [[ \$IS_BITLOCKER =~ true ]]; then
    qrencode -o \$DOCS_QR "https://www.wikihow.com/Turn-Off-BitLocker"
    _EXITLOCK=1
    _RETCODE=0
    while [[ \$_EXITLOCK -ne 0 ]]; do
        run0 --user=liveuser yad \
            --on-top \
            --timeout=10 \
            --image=\$DOCS_QR \
            --text="\$WARNING_MSG" \
            --button="Yes, I'm aware, continue":0 --button="Cancel installation":10
        _RETCODE=\$?
        case \$_RETCODE in
            0) _EXITLOCK=0; ;;
            10) _EXITLOCK=0; pkill liveinst; pkill firefox; exit 0 ;;
        esac
    done
fi
%end

# Remove the Fedora efi dir
%pre-install --erroronfail
rm -rf /mnt/sysroot/boot/efi/EFI/fedora
%end

# Relabel the boot partition
%pre-install --erroronfail --log=/tmp/anaconda_custom_logs/repartitioning.log
set -x
xboot_dev=\$(findmnt -o SOURCE --nofsroot --noheadings -f --target /mnt/sysroot/boot)
if [[ -z \$xboot_dev ]]; then
  echo "ERROR: xboot_dev not found"
  exit 1
fi
e2label "\$xboot_dev" "bamos_xboot"
%end

# Open a dialog with the installation logs on error
%onerror
run0 --user=liveuser yad \
    --timeout=0 \
    --text-info \
    --no-buttons \
    --width=600 \
    --height=400 \
    --text="An error occurred during installation. Please report this issue to the developers." \
    < /tmp/anaconda.log
%end

ostreecontainer --url=$imageref:$imagetag --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/flatpak-restore-selinux-labels.ks

EOF

# ── Signed Images: bootc switch to registry for verified boot ────────────────
cat <<EOF >/usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%post --erroronfail --log=/tmp/anaconda_custom_logs/bootc-switch.log
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $imageref:$imagetag
%end
EOF

# ── NVIDIA-specific fixes ────────────────────────────────────────────────────
if [[ $imageref == *-nvidia* ]]; then
    echo "Applying NVIDIA-specific installer fixes..."

    # GSK_RENDERER=gl workaround for GTK apps not opening on NVIDIA
    mkdir -p /etc/environment.d /etc/skel/.config/environment.d
    echo "GSK_RENDERER=gl" >>/etc/environment.d/99-nvidia-fix.conf
    echo "GSK_RENDERER=gl" >>/etc/skel/.config/environment.d/99-nvidia-fix.conf

    # Reinstall nouveau drivers alongside NVIDIA
    for pkg in nvidia-gpu-firmware mesa-vulkan-drivers; do
        dnf -yq reinstall --allowerasing $pkg 2>/dev/null ||
            dnf -yq install --allowerasing $pkg 2>/dev/null || true
    done
fi

# ── Copy shared installer system files ────────────────────────────────────────
if [[ -d /installer/shared ]]; then
    echo "Copying shared installer files..."
    cp -af /installer/shared/. / 2>/dev/null || true
fi

# ── DE-specific installer system files ───────────────────────────────────────
case "$desktop_env" in
    gnome)
        if [[ -d /installer/bamos-gnome ]]; then
            echo "Copying GNOME-specific installer files..."
            cp -af /installer/bamos-gnome/. / 2>/dev/null || true
        fi
        # Hide Fedora welcome screen
        sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' \
            /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop 2>/dev/null || :
        ;;
    kde)
        if [[ -d /installer/bamos-kde ]]; then
            echo "Copying KDE-specific installer files..."
            cp -af /installer/bamos-kde/. / 2>/dev/null || true
        fi
        ;;
    cosmic)
        if [[ -d /installer/bamos-cosmic ]]; then
            echo "Copying COSMIC-specific installer files..."
            cp -af /installer/bamos-cosmic/. / 2>/dev/null || true
        fi
        ;;
esac

# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf /root/packages 2>/dev/null || true

echo "=== BamOS: ISO Configuration Complete ==="
