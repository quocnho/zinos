#!/usr/bin/env bash
# BamOS: 00-repos.sh — Enable all package repositories
set -euo pipefail

echo "=== BamOS: Enabling Repositories ==="

FEDORA_VERSION=$(rpm -E %fedora)

dnf5 -y install dnf5-plugins

# RPM Fusion
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm

# CachyOS kernel repos
for copr in bieszczaders/kernel-cachyos bieszczaders/kernel-cachyos-addons; do
    dnf5 -y copr enable "$copr" fedora-${FEDORA_VERSION}-x86_64
done

# ublue-os repos (for bazzite, packages)
for copr in ublue-os/bazzite ublue-os/packages; do
    dnf5 -y copr enable "$copr" fedora-${FEDORA_VERSION}-x86_64 2>/dev/null || true
done

# Terra repos (for mesa, multimedia)
rpm --import https://repos.fyralabs.com/terra${FEDORA_VERSION}/key.asc 2>/dev/null || true
rpm --import https://repos.fyralabs.com/terra${FEDORA_VERSION}-mesa/key.asc 2>/dev/null || true
dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release 2>/dev/null || true
dnf5 -y install --nogpgcheck --repofrompath 'terra-mesa,https://repos.fyralabs.com/terra$releasever' terra-release-mesa 2>/dev/null || true
sed -i '/^priority=/d' /etc/yum.repos.d/terra*.repo 2>/dev/null || true

echo "=== BamOS: Repositories Enabled ==="
