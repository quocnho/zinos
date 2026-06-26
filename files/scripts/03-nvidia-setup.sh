#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: NVIDIA Setup ==="

IMAGE_NAME="${IMAGE_NAME:-bamos}"

if [[ "$IMAGE_NAME" != *-nvidia ]]; then
    echo "Not an NVIDIA variant — skipping."
    exit 0
fi

# NVIDIA is already handled in 00-build-setup.sh
# This script is a placeholder for any additional NVIDIA configuration.

echo "NVIDIA configuration complete."

echo "=== BamOS: NVIDIA Setup Complete ==="
