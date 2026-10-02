#!/bin/bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/zvzt/macos-debloat/main"
INSTALL="$HOME/.macos-debloat"
PRESETS="$INSTALL/presets"
STATE="$INSTALL/state"
CONFIG="$INSTALL/config.json"
USER_AGENT="$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist"
SYSTEM_DAEMON="/Library/LaunchDaemons/com.zot.macos-debloat.system.plist"
TMP="$(mktemp -d)"
UID_NUM="$(id -u)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

printf '\nmacOS Debloat\n==================\n\n'

if [ "$(uname -s)" != "Darwin" ]; then
    echo "macOS Debloat only supports macOS."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required."
    echo "Install Python 3 first, then run this installer again."
    echo "Homebrew users can run: brew install python"
    exit 1
fi

mkdir -p "$PRESETS" "$STATE" "$HOME/Library/LaunchAgents"

echo "Downloading the latest macOS Debloat files..."
for file in debloat presets/balanced.txt presets/aggressive.txt presets/siri.txt presets/apple-intelligence.txt; do
    mkdir -p "$TMP/$(dirname "$file")"
    curl -fsSL "$REPO/$file?$(date +%s)" -o "$TMP/$file"
done

python3 -m py_compile "$TMP/debloat"
chmod +x "$TMP/debloat"


cp "$TMP/debloat" "$INSTALL/debloat"
cp "$TMP/presets/balanced.txt" "$PRESETS/balanced.txt"
cp "$TMP/presets/aggressive.txt" "$PRESETS/aggressive.txt"
cp "$TMP/presets/siri.txt" "$PRESETS/siri.txt"
cp "$TMP/presets/apple-intelligence.txt" "$PRESETS/apple-intelligence.txt"
chmod +x "$INSTALL/debloat"

sudo mkdir -p /usr/local/bin
sudo ln -sf "$INSTALL/debloat" /usr/local/bin/debloat

if [ ! -f "$CONFIG" ]; then
    echo
    echo "First-time setup:"
    if [ -t 0 ]; then
        "$INSTALL/debloat" configure --no-apply
    else
        echo "No interactive terminal detected; using safe defaults."
        "$INSTALL/debloat" configure --defaults --no-apply
    fi
else
    echo "Existing configuration preserved."
    "$INSTALL/debloat" config
fi

echo
printf 'Administrator access may be requested for system launchd targets.\n'
sudo -v

"$INSTALL/debloat" apply

launchctl bootout "gui/$UID_NUM/com.zot.macos-debloat" >/dev/null 2>&1 || true
rm -f "$USER_AGENT"
# Older releases installed a root LaunchDaemon that executed the user-owned
# macOS Debloat script. Remove it during every install/update; launchctl disable overrides
# persist without that background helper.
sudo launchctl bootout system/com.zot.macos-debloat.system >/dev/null 2>&1 || true
sudo rm -f "$SYSTEM_DAEMON"

cat > "$USER_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zot.macos-debloat</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL/debloat</string>
        <string>reapply-user</string>
        <string>--quiet</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$UID_NUM" "$USER_AGENT" >/dev/null 2>&1 || true

printf '\n========================================\n'
printf 'macOS Debloat installation/update complete.\n'
printf '========================================\n\n'
printf 'Common commands:\n'
printf '  debloat status                 Show current state\n'
printf '  debloat configure              Change profile/Siri/AI/Spotlight choices\n'
printf '  debloat clean                  Interactive cache/log/tool cleanup\n'
printf '  debloat apply --dry-run        Preview changes without applying them\n'
printf '  debloat apply                  Apply the saved configuration\n'
printf '  debloat doctor                 Check installation and macOS support\n'
printf '  debloat restore                Restore changes made by macOS Debloat\n'
printf '\nFeature shortcuts:\n'
printf '  debloat siri keep|disable\n'
printf '  debloat intelligence keep|disable\n'
printf '  debloat spotlight status|keep|off|on|reindex\n'
printf '\nRun debloat help for the full command list.\n'
printf 'System launchd disable overrides persist without a root background helper.\n'
printf 'Restart macOS once after first install or a major profile change.\n\n'
