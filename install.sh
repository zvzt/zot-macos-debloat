#!/bin/bash
set -euo pipefail

REPO="https://zxt.lol/debloat"
INSTALL="$HOME/.zxt-macos-debloat"
PRESETS="$INSTALL/presets"
STATE="$INSTALL/state"
CONFIG="$INSTALL/config.json"
USER_AGENT="$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"
SYSTEM_DAEMON="/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"
TMP="$(mktemp -d)"
UID_NUM="$(id -u)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

printf '\nZXT macOS Debloat\n==================\n\n'

if [ "$(uname -s)" != "Darwin" ]; then
    echo "ZXT only supports macOS."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python 3 is required."
    echo "Install Python 3 first, then run this installer again."
    echo "Homebrew users can run: brew install python"
    exit 1
fi

mkdir -p "$PRESETS" "$STATE" "$HOME/Library/LaunchAgents"

echo "Downloading the latest ZXT files..."
for file in zxt presets/balanced.txt presets/aggressive.txt presets/siri.txt presets/apple-intelligence.txt; do
    mkdir -p "$TMP/$(dirname "$file")"
    curl -fsSL "$REPO/$file?$(date +%s)" -o "$TMP/$file"
done

python3 -m py_compile "$TMP/zxt"
chmod +x "$TMP/zxt"

if [ -f "$PRESETS/zxt-default.txt" ]; then
    cp "$PRESETS/zxt-default.txt" "$STATE/legacy-zxt-default.txt" || true
fi

cp "$TMP/zxt" "$INSTALL/zxt"
cp "$TMP/presets/balanced.txt" "$PRESETS/balanced.txt"
cp "$TMP/presets/aggressive.txt" "$PRESETS/aggressive.txt"
cp "$TMP/presets/siri.txt" "$PRESETS/siri.txt"
cp "$TMP/presets/apple-intelligence.txt" "$PRESETS/apple-intelligence.txt"
chmod +x "$INSTALL/zxt"

sudo mkdir -p /usr/local/bin
sudo ln -sf "$INSTALL/zxt" /usr/local/bin/zxt

if [ ! -f "$CONFIG" ]; then
    echo
    echo "First-time setup:"
    if [ -t 0 ]; then
        "$INSTALL/zxt" configure --no-apply
    else
        echo "No interactive terminal detected; using safe defaults."
        "$INSTALL/zxt" configure --defaults --no-apply
    fi
else
    echo "Existing configuration preserved."
    "$INSTALL/zxt" config
fi

echo
printf 'Administrator access may be requested for system launchd targets.\n'
sudo -v

"$INSTALL/zxt" apply

launchctl bootout "gui/$UID_NUM/com.zxt.macos-debloat" >/dev/null 2>&1 || true
rm -f "$USER_AGENT"
# Older releases installed a root LaunchDaemon that executed the user-owned
# ZXT script. Remove it during every install/update; launchctl disable overrides
# persist without that background helper.
sudo launchctl bootout system/com.zxt.macos-debloat.system >/dev/null 2>&1 || true
sudo rm -f "$SYSTEM_DAEMON"

cat > "$USER_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zxt.macos-debloat</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL/zxt</string>
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
printf 'ZXT installation/update complete.\n'
printf '========================================\n\n'
printf 'Common commands:\n'
printf '  zxt status                 Show current state\n'
printf '  zxt configure              Change profile/Siri/AI/Spotlight choices\n'
printf '  zxt clean                  Interactive cache/log/tool cleanup\n'
printf '  zxt apply --dry-run        Preview changes without applying them\n'
printf '  zxt apply                  Apply the saved configuration\n'
printf '  zxt doctor                 Check installation and macOS support\n'
printf '  zxt restore                Restore changes made by ZXT\n'
printf '\nFeature shortcuts:\n'
printf '  zxt siri keep|disable\n'
printf '  zxt intelligence keep|disable\n'
printf '  zxt spotlight status|keep|off|on|reindex\n'
printf '\nRun zxt help for the full command list.\n'
printf 'System launchd disable overrides persist without a root background helper.\n'
printf 'Restart macOS once after first install or a major profile change.\n\n'
