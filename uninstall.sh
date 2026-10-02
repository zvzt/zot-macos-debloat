#!/bin/bash
set -euo pipefail

INSTALL="$HOME/.macos-debloat"
USER_AGENT="$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist"
SYSTEM_DAEMON="/Library/LaunchDaemons/com.zot.macos-debloat.system.plist"
UID_NUM="$(id -u)"

printf '\nmacOS Debloat - Uninstall\n=============================\n\n'

if [ -x "$INSTALL/debloat" ]; then
    echo "Restoring managed changes first..."
    "$INSTALL/debloat" restore || true
fi

launchctl bootout "gui/$UID_NUM/com.zot.macos-debloat" >/dev/null 2>&1 || true
rm -f "$USER_AGENT"

sudo launchctl bootout system/com.zot.macos-debloat.system >/dev/null 2>&1 || true
sudo rm -f "$SYSTEM_DAEMON"

if [ -L /usr/local/bin/debloat ] || [ -f /usr/local/bin/debloat ]; then
    sudo rm -f /usr/local/bin/debloat
fi

rm -rf "$INSTALL"

echo "macOS Debloat has been uninstalled."
echo "Restart macOS if you want restored services to return immediately."
