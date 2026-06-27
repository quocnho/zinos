#!/usr/bin/env bash
# Add BamOS Flatpak wrappers to PATH
FLATPAK_WRAPPERS="/usr/local/bin/flatpak"

if [ -d "$FLATPAK_WRAPPERS" ] && [[ ":$PATH:" != *":$FLATPAK_WRAPPERS:"* ]]; then
    export PATH="$FLATPAK_WRAPPERS:$PATH"
fi
