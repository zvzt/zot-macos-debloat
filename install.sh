#!/bin/bash
set -euo pipefail

REPO="https://api.github.com/repositories/1356850441/contents"
INSTALL="$HOME/.zot"
PRESETS="$INSTALL/presets"
LIB="$INSTALL/lib"
STATE="$INSTALL/state"
OLD_INSTALL="$HOME/.macos-debloat"
OLD_AGENT="$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf '\nZot\n===\n\n'
[ "$(uname -s)" = Darwin ] || { echo "Zot only supports macOS."; exit 1; }

mkdir -p "$PRESETS" "$LIB" "$STATE" "$TMP/lib" "$TMP/presets"

fetch(){
  local path="$1"
  mkdir -p "$TMP/$(dirname "$path")"
  curl -fsSL -H 'Accept: application/vnd.github.raw+json' "$REPO/$path?ref=main&cache=$(date +%s)" -o "$TMP/$path"
}

echo "Downloading Zot..."
for file in zot lib/common.sh lib/clean.sh lib/analyze.sh lib/system.sh lib/hub.sh presets/balanced.txt presets/aggressive.txt presets/siri.txt presets/apple-intelligence.txt; do
  fetch "$file"
done

bash -n "$TMP/zot" "$TMP"/lib/*.sh
chmod +x "$TMP/zot"

if [ -d "$OLD_INSTALL" ]; then
  echo "Migrating previous configuration..."
  [ -f "$OLD_INSTALL/state/disabled-services.txt" ] && cp "$OLD_INSTALL/state/disabled-services.txt" "$STATE/disabled-services.txt" || true
  [ -f "$OLD_INSTALL/state/spotlight-changed.txt" ] && cp "$OLD_INSTALL/state/spotlight-changed.txt" "$STATE/spotlight-changed.txt" || true
  if [ -f "$OLD_INSTALL/config.json" ] && [ ! -f "$INSTALL/config" ]; then
    profile="$(grep -E '"profile"' "$OLD_INSTALL/config.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)"
    siri="$(grep -E '"siri"' "$OLD_INSTALL/config.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)"
    intelligence="$(grep -E '"intelligence"' "$OLD_INSTALL/config.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)"
    spotlight="$(grep -E '"spotlight"' "$OLD_INSTALL/config.json" | head -1 | sed -E 's/.*: *"([^"]+)".*/\1/' || true)"
    cat > "$INSTALL/config" <<EOF
profile=${profile:-balanced}
siri=${siri:-keep}
intelligence=${intelligence:-keep}
spotlight=${spotlight:-keep}
EOF
  fi
fi

cp "$TMP/zot" "$INSTALL/zot"
cp "$TMP"/lib/*.sh "$LIB/"
cp "$TMP"/presets/*.txt "$PRESETS/"
chmod +x "$INSTALL/zot"

if [ -d /usr/local/bin ] && [ -w /usr/local/bin ]; then
  ln -sf "$INSTALL/zot" /usr/local/bin/zot
else
  sudo mkdir -p /usr/local/bin
  sudo ln -sf "$INSTALL/zot" /usr/local/bin/zot
fi

# Remove the previous tool-owned helper. Zot no longer installs a background job.
launchctl bootout "gui/$(id -u)/com.zot.macos-debloat" >/dev/null 2>&1 || true
rm -f "$OLD_AGENT"
if [ -e /usr/local/bin/debloat ] || [ -L /usr/local/bin/debloat ]; then sudo rm -f /usr/local/bin/debloat; fi
if [ -d "$OLD_INSTALL" ]; then rm -rf "$OLD_INSTALL"; fi

printf '\nZot installed.\n\nRun:\n  zot\n\nNo extra runtime, Python package, or background service was installed.\n'
