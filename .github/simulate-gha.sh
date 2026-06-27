#!/usr/bin/env bash
# ============================================================================
#  BamOS GHA Simulator — simulate GitHub Actions workflow locally
#  Uses distrobox/podman to replicate the CI/CD pipeline
# ============================================================================
# Usage: bash .github/simulate-gha.sh [edition] [steps]
#   edition: kde, kde-nvidia, gnome, gnome-nvidia, cosmic, cosmic-nvidia (default: kde)
#   steps:   validate, build, iso, release, all (default: all)
# ============================================================================

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────────
EDITION="${1:-kde}"
STEPS="${2:-all}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONTAINER_NAME="bamos-gha-$$"
SCRIPT_NAME="$(basename "$0")"
START_TIME=$(date +%s)

# ── GitHub Actions environment simulation ─────────────────────────────────────
GHA_ENV=(
    -e GITHUB_ACTIONS=true
    -e GITHUB_WORKFLOW="Build BamOS"
    -e GITHUB_RUN_ID="$RANDOM"
    -e GITHUB_RUN_NUMBER="1"
    -e GITHUB_REPOSITORY="quocnho/bamos"
    -e GITHUB_SHA="$(cd "$HERE" && git rev-parse HEAD 2>/dev/null || echo 'test')"
    -e GITHUB_REF_NAME="main"
    -e GITHUB_REF="refs/heads/main"
    -e GITHUB_WORKSPACE="/workspace"
    -e IMAGE_NAME="$EDITION"
    -e IMAGE_REGISTRY="localhost"
    -e IMAGE_NAMESPACE="bamos"
    -e HOME="/root"
)

# ── Helpers ────────────────────────────────────────────────────────────────────
header() {
    printf '\n╔══════════════════════════════════════════╗\n'
    printf '║  %-38s ║\n' "$1"
    printf '╚══════════════════════════════════════════╝\n'
}

step() {
    printf '\n▶ %s\n' "$1"
}

ok()   { printf '  ✅ %s\n' "$1"; }
warn() { printf '  ⚠️  %s\n' "$1"; }
fail() { printf '  ❌ %s\n' "$1"; exit 1; }

# ── Header ─────────────────────────────────────────────────────────────────────
cat << 'WELCOME'

╔══════════════════════════════════════════════════════╗
║           BamOS GHA Simulator                        ║
║  GitHub Actions workflow simulation (local)          ║
╚══════════════════════════════════════════════════════╝

WELCOME
printf '  📦 Edition: %s\n' "$EDITION"
printf '  🏠 Project: %s\n' "$HERE"
printf '  📋 Steps:   %s\n' "$STEPS"
printf '  🐳 Container: %s\n\n' "$CONTAINER_NAME"

# ── Step 0: Setup container ────────────────────────────────────────────────────
step "0/5: Preparing test environment"

# Remove old container if exists
podman rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Create container
podman run -d --privileged --network=host --name "$CONTAINER_NAME" \
    -v "$HERE:/workspace:Z" \
    "${GHA_ENV[@]}" \
    fedora:44 sleep infinity >/dev/null 2>&1
ok "Container $CONTAINER_NAME created"

# Install dependencies
podman exec "$CONTAINER_NAME" bash -c '
    set -euo pipefail
    echo "    Installing build tools..."
    dnf5 -y install dnf5-plugins -q 2>/dev/null
    dnf5 -y install podman git jq python3-pip shellcheck -q 2>&1 | tail -1
    pip3 install yamllint -q 2>/dev/null || true
    echo "    Tools installed."
' 2>&1
ok "Build tools installed"

# ── Step 1: Validate ───────────────────────────────────────────────────────────
validate() {
    header "VALIDATION STAGE"

    step "1.1: Recipe YAML validation"
    podman exec "$CONTAINER_NAME" bash -c '
        cd /workspace
        for r in recipes/bamos-*.yml; do
            python3 -c "import yaml; yaml.safe_load(open(\"$r\"))" 2>&1 && \
                echo "  ✅ $(basename $r)" || echo "  ❌ $(basename $r)"
        done
    ' 2>&1

    step "1.2: Workflow YAML validation"
    podman exec "$CONTAINER_NAME" bash -c '
        cd /workspace
        python3 -c "
import yaml
with open(\".github/workflows/build.yml\") as f:
    c = f.read()
wf = yaml.safe_load(c.replace(chr(10)+\"on:\", chr(10)+\"trigger:\", 1))
j = list(wf[\"jobs\"].keys())
e = wf[\"env\"]
print(f\"  Jobs: {j}\")
print(f\"  Registry: {e[\"IMAGE_REGISTRY\"]}/{e[\"IMAGE_NAMESPACE\"]}\")
print(f\"  Fedora: {e[\"FEDORA_VERSION\"]}\")
" 2>&1
    ' 2>&1
    ok "Workflow valid"

    step "1.3: Shellcheck all scripts"
    podman exec "$CONTAINER_NAME" bash -c '
        cd /workspace
        ERRORS=0
        for f in files/scripts/*.sh files/system/usr/libexec/bamos/* files/system/usr/bin/bamos; do
            if shellcheck --severity=warning "$f" 2>/dev/null; then
                echo "  ✅ $(basename $f)"
            else
                echo "  ❌ $(basename $f)"
                ERRORS=$((ERRORS + 1))
            fi
        done
        exit $ERRORS
    ' 2>&1 && ok "All scripts pass shellcheck" || fail "Shellcheck errors found"

    ok "Validation complete"
}

# ── Step 2: Build images ───────────────────────────────────────────────────────
build_images() {
    header "BUILD STAGE (Job: build-images)"

    step "2.1: blue-build image build"
    echo "    Building $EDITION (this takes 10-30 minutes)..."

    podman exec "$CONTAINER_NAME" bash -c "
        cd /workspace
        export IMAGE_NAME=$EDITION
        export CI=true

        # Use bluebuild CLI from host (bind-mounted at /usr/local/bin)
        if command -v /usr/local/bin/bluebuild &>/dev/null; then
            sudo /usr/local/bin/bluebuild build recipes/${EDITION%%-nvidia}.yml
        else
            echo '    ⚠️  bluebuild not available in container'
            echo '    Using host bluebuild via podman socket...'
            sudo bluebuild build recipes/${EDITION%%-nvidia}.yml
        fi
    " 2>&1 | tail -20

    ok "Image built: localhost/bamos-$EDITION:latest"

    step "2.2: Verify image exists"
    podman exec "$CONTAINER_NAME" bash -c '
        podman images --format "table {{.Repository}}:{{.Tag}} {{.Size}}" | grep -E "bamos|localhost" || true
    ' 2>&1

    ok "Build-images stage complete"
}

# ── Step 3: Generate ISO ───────────────────────────────────────────────────────
build_isos() {
    header "ISO STAGE (Job: build-isos)"

    step "3.1: Generate ISO via Titanoboa"
    # Use the host's bluebuild generate-iso
    sudo bluebuild generate-iso \
        --iso-name "BamOS-${EDITION}-main-amd64.iso" \
        image "localhost/bamos-${EDITION}:latest" \
        2>&1 | tail -5

    ok "ISO generated"

    step "3.2: Generate checksum"
    cd "$HERE"
    if [ -f "BamOS-${EDITION}-main-amd64.iso" ]; then
        sha256sum "BamOS-${EDITION}-main-amd64.iso" | tee "CHECKSUM-${EDITION}.txt"
        ok "Checksum generated"
    else
        ISO_FILE=$(ls -1 *.iso 2>/dev/null | head -1 || true)
        if [ -n "$ISO_FILE" ]; then
            sha256sum "$ISO_FILE" | tee "CHECKSUM-${EDITION}.txt"
            ok "Checksum generated (from $(basename "$ISO_FILE"))"
        else
            warn "No ISO file found — image may need to be built first"
        fi
    fi

    ok "Build-isos stage complete"
}

# ── Step 4: Release simulation ─────────────────────────────────────────────────
release() {
    header "RELEASE STAGE (Job: release)"

    step "4.1: List artifacts"
    cd "$HERE"
    echo "  ISO files:"
    ls -lh *.iso 2>/dev/null | sed 's/^/    /' || warn "No ISO files found"
    echo "  Checksum files:"
    ls -lh CHECKSUM-*.txt 2>/dev/null | sed 's/^/    /' || warn "No checksum files found"

    step "4.2: Simulate R2 upload (local dir)"
    mkdir -p /tmp/bamos-r2-sim
    cp *.iso CHECKSUM-*.txt /tmp/bamos-r2-sim/ 2>/dev/null || true
    echo "  Uploaded to /tmp/bamos-r2-sim/:"
    ls -lh /tmp/bamos-r2-sim/ | sed 's/^/    /'

    step "4.3: Create stable download links"
    shopt -s nullglob
    for f in *.iso; do
        BASENAME=$(basename "$f" .iso)
        EDITION=$(echo "$BASENAME" | sed -E 's/-(nightly-[0-9]+|main|develop|master)-amd64$//')
        EDITION_LOWER=$(echo "$EDITION" | tr '[:upper:]' '[:lower:]')
        ln -sf "$HERE/$f" "/tmp/bamos-r2-sim/${EDITION}.iso" 2>/dev/null || true
        ln -sf "$HERE/$f" "/tmp/bamos-r2-sim/${EDITION_LOWER}-latest.iso" 2>/dev/null || true
        printf '    📦 %s.iso  →  %s/BamOS-KDE.iso\n' "$BASENAME" "https://dl.bamos.info"
    done
    shopt -u nullglob

    step "4.4: Simulate GitHub Release"
    echo "  Tag: nightly-$RANDOM"
    echo "  Prerelease: true"
    echo "  Body: Automated build from commit $(cd "$HERE" && git rev-parse --short HEAD 2>/dev/null || echo 'test')"

    ok "Release stage complete"
}

# ── Execute requested steps ────────────────────────────────────────────────────
case "$STEPS" in
    validate) validate ;;
    build)    validate && build_images ;;
    iso)      validate && build_images && build_isos ;;
    release)  validate && build_images && build_isos && release ;;
    all)      validate && build_images && build_isos && release ;;
    *)        echo "Unknown steps: $STEPS"; exit 1 ;;
esac

# ── Summary ────────────────────────────────────────────────────────────────────
DURATION=$(( $(date +%s) - START_TIME ))
cat << SUMMARY

╔══════════════════════════════════════════╗
║  Simulation Complete                     ║
╚══════════════════════════════════════════╝
  Edition:   $EDITION
  Steps:     $STEPS
  Duration:  $((DURATION / 60))m $((DURATION % 60))s
  Container: $CONTAINER_NAME

  Artifacts: /tmp/bamos-r2-sim/
  Cleanup:   podman rm -f $CONTAINER_NAME

SUMMARY
