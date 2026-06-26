#!/usr/bin/env python3
"""
BamOS Bazaar hooks — called by Bazaar before Flatpak transactions.
Returns exit code 0 to allow, non-zero to block.
"""

import json
import sys


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, FileNotFoundError):
        sys.exit(0)

    appid = data.get("appid", "")
    action = data.get("action", "")

    if action == "install" and appid.startswith("com.system76."):
        print(f"INFO: {appid} is available natively on COSMIC.")
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()
