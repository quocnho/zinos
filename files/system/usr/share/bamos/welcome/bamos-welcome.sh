#!/usr/bin/env bash
# ============================================================================
#  BamOS Linux — GUI Welcome Screen Script
#
#  Launched on first login via xdg/autostart.  Displays a YAD-based or
#  zenity-based welcome dialog with edition info, quick links, and next steps.
#
#  Falls back gracefully if neither YAD nor zenity is installed.
# ============================================================================
set -ouex pipefail

BAMOS_EDITION="${BAMOS_EDITION:-BamOS Linux}"
LOGO_PATH="/usr/share/pixmaps/bamos-logo.png"
DEFAULT_LOGO="/usr/share/icons/hicolor/256x256/apps/fedora-logo-icon.png"

# ── Detect available dialog tool ────────────────────────────────────────────
if command -v yad &>/dev/null; then
    DIALOG="yad"
elif command -v zenity &>/dev/null; then
    DIALOG="zenity"
else
    # No graphical dialog available — write to journal and exit silently
    logger -t bamos-welcome "No graphical dialog tool found (yad/zenity). Skipping welcome screen."
    exit 0
fi

# ── Pick logo ───────────────────────────────────────────────────────────────
[[ -f "$LOGO_PATH" ]] || LOGO_PATH="$DEFAULT_LOGO"
[[ -f "$LOGO_PATH" ]] || LOGO_PATH=""

# ── Gather system info ──────────────────────────────────────────────────────
KERNEL="$(uname -r 2>/dev/null || echo 'N/A')"
UPTIME="$(uptime -p 2>/dev/null | sed 's/^up //' || echo 'N/A')"
MEM_FREE="$(free -h 2>/dev/null | awk '/^Mem:/ {print $7}' || echo 'N/A')"
DISK_FREE="$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo 'N/A')"

# ── Build message ───────────────────────────────────────────────────────────
WELCOME_MSG="Welcome to ${BAMOS_EDITION}!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔹 Edition:    ${BAMOS_EDITION}
🔹 Kernel:     ${KERNEL}
🔹 Uptime:     ${UPTIME}
🔹 Mem Free:   ${MEM_FREE}
🔹 Disk Free:  ${DISK_FREE}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 Documentation:
   https://github.com/quocnho/bamos

💬 Need help? Run: bamos --help
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Show dialog ─────────────────────────────────────────────────────────────
case "$DIALOG" in
    yad)
        yad --info \
            --title="Welcome to BamOS Linux" \
            --text="$WELCOME_MSG" \
            --window-icon="$LOGO_PATH" \
            --image="$LOGO_PATH" \
            --width=500 --height=400 \
            --button="Get Started!":0 \
            --center \
            --on-top
        ;;
    zenity)
        zenity --info \
            --title="Welcome to BamOS Linux" \
            --text="$WELCOME_MSG" \
            --width=500 \
            --ok-label="Get Started!" \
            --window-icon="$LOGO_PATH" \
            --timeout=60 2>/dev/null
        ;;
esac

# Record that welcome was shown (used by first-boot logic)
mkdir -p /var/lib/bamos
touch /var/lib/bamos/welcome-shown
logger -t bamos-welcome "Welcome screen displayed for ${BAMOS_EDITION}."
