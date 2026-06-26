#!/usr/bin/env bash
set -ouex pipefail

echo "=== BamOS: Post-Build ==="

# ── Set default hostname ─────────────────────────────────────────────────────
echo "bamos" > /etc/hostname

echo "=== BamOS: Post-Build Complete ==="
