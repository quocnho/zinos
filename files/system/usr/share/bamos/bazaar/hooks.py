#!/usr/bin/env python3
# BamOS Bazaar hooks — post-install and pre-install actions
# These hooks are called by the bazaar software center after/before
# installing or removing applications.

import json
import os
import subprocess


def post_install(app_id):
    """Called after an application is installed via Bazaar."""
    # Update desktop database
    subprocess.run(["update-desktop-database", "-q"], capture_output=True)
    # Update icon cache
    subprocess.run(
        ["gtk-update-icon-cache", "-f", "-t", "/usr/share/icons/hicolor"],
        capture_output=True,
    )


def pre_remove(app_id):
    """Called before an application is removed via Bazaar."""
    pass


def post_remove(app_id):
    """Called after an application is removed via Bazaar."""
    subprocess.run(["update-desktop-database", "-q"], capture_output=True)
