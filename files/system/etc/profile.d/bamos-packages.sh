#!/usr/bin/env bash
# BamOS package root environment integration.

BAMOS_ROOT="/var/lib/bamos/packages"

if [[ -d "$BAMOS_ROOT/usr" ]]; then
    export PATH="$BAMOS_ROOT/usr/bin:$BAMOS_ROOT/usr/sbin:$PATH"
    export XDG_DATA_DIRS="$BAMOS_ROOT/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    export MANPATH="$BAMOS_ROOT/usr/share/man${MANPATH:+:$MANPATH}"
    export GI_TYPELIB_PATH="$BAMOS_ROOT/usr/lib64/girepository-1.0:$BAMOS_ROOT/usr/lib/girepository-1.0${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
fi
