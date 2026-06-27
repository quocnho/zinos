#!/usr/bin/env bash
# BamOS: 01-kernel.sh — Remove Fedora kernel, install CachyOS kernel
set -euo pipefail

echo "=== BamOS: Installing CachyOS Kernel ==="

# Remove Fedora kernel
dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core \
    kernel-modules-extra kernel-tools kernel-tools-libs zram-generator-defaults 2>/dev/null || true

# Install CachyOS kernel
dnf5 -y --setopt=tsflags=noscripts install kernel-cachyos kernel-cachyos-devel-matched

echo "=== BamOS: Kernel Installed ==="
