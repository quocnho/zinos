#!/usr/bin/env bash
# BamOS ublue-os bazaar hooks (compatible with ublue-bazaar)
import os
import subprocess


def post_install(app_id):
    subprocess.run(["update-desktop-database", "-q"], capture_output=True)


def post_remove(app_id):
    subprocess.run(["update-desktop-database", "-q"], capture_output=True)
