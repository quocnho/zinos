#!/usr/bin/env bash
# BamOS Test Harness — simulate GitHub Actions build locally via distrobox
# Usage: bash .test-harness/run-test.sh [edition]

set -euo pipefail

EDITION="${1:-kde}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONTAINER_NAME="bamos-test-$$"
START_TIME=$(date +%s)

echo "╔══════════════════════════════════════════╗"
echo "║   BamOS Local Test Harness              ║"
echo "╚══════════════════════════════════════════╝"
echo "📦 Edition: $EDITION"
echo ""

# Prerequisites
if ! command -v distrobox &>/dev/null; then
    echo "ERROR: Install distrobox first:"
    echo "  sudo dnf5 -y install distrobox"
    exit 1
fi

# Step 1: Create container
echo "▶ 1/4: Creating distrobox..."
distrobox create --image fedora:44 --name "$CONTAINER_NAME" \
    --additional-flags "--privileged --network=host -v $HERE:/workspace:z" 2>&1 | tail -2

# Step 2: Install tools
echo "▶ 2/4: Installing bluebuild + podman..."
distrobox enter "$CONTAINER_NAME" -- bash -c '
    sudo dnf5 -y install dnf5-plugins
    sudo dnf5 -y copr enable ublue-os/packages
    sudo dnf5 -y install bluebuild podman git jq python3-pip
    pip3 install yamllint
    sudo dnf5 clean all
' 2>&1 | grep -E "(Complete|Error)" || true

# Step 3: Validate
echo "▶ 3/4: Validating project..."
distrobox enter "$CONTAINER_NAME" -- bash -c '
    cd /workspace
    echo "  Recipes:"; for r in recipes/*.yml; do
        python3 -c "import yaml; yaml.safe_load(open(\"$r\")); print(\"    ✅ $r\")" 2>&1
    done
    echo "  Scripts:"; for f in files/scripts/*.sh; do
        shellcheck --severity=warning "$f" 2>&1 && echo "    ✅ $(basename $f)" || true
    done
    echo "  Libexec:"; for f in files/system/usr/libexec/bamos/*; do
        shellcheck --severity=warning "$f" 2>&1 && echo "    ✅ $(basename $f)" || true
    done
    echo "  Justfile:"; just --list 2>&1 | head -3
' 2>&1

# Step 4: Build
echo "▶ 4/4: Building $EDITION (may take 10-30 min)..."
distrobox enter "$CONTAINER_NAME" -- bash -c "
    cd /workspace
    export IMAGE_NAME=$EDITION
    sudo bluebuild build recipes/${EDITION%%-nvidia}.yml
" 2>&1

# Duration
echo ""
echo "⏱️  $((( $(date +%s) - START_TIME ) / 60))m total"
echo "🗑️  Cleanup: distrobox stop $CONTAINER_NAME && distrobox rm $CONTAINER_NAME"
echo "✅ Test complete (check output above for errors)"
