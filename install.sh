#!/bin/bash
set -euo pipefail

REPO="https://api.github.com/repositories/1356850441/contents"
INSTALL="$HOME/.zot"
PRESETS="$INSTALL/presets"
LIB="$INSTALL/lib"
STATE="$INSTALL/state"
TMP="$(mktemp -d)"
UID_NUM="$(id -u)"
FIRST_INSTALL=0
[ ! -e "$INSTALL" ] && FIRST_INSTALL=1
trap 'rm -rf "$TMP"' EXIT

printf '\nZot\n===\n\n'
[ "$(uname -s)" = Darwin ] || { echo "Zot only supports macOS."; exit 1; }

fetch(){
  local path="$1"
  mkdir -p "$TMP/$(dirname "$path")"
  curl -fsSL -H 'Accept: application/vnd.github.raw+json' "$REPO/$path?ref=main&cache=$(date +%s)" -o "$TMP/$path"
}

legacy_artifacts(){
  local p
  for p in \
    "$HOME/.macos-debloat" \
    "$HOME/.zxt-macos-debloat" \
    "/usr/local/bin/debloat" \
    "/usr/local/bin/zxt" \
    "$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist" \
    "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist" \
    "/Library/LaunchAgents/com.zot.macos-debloat.plist" \
    "/Library/LaunchAgents/com.zxt.macos-debloat.plist" \
    "/Library/LaunchDaemons/com.zot.macos-debloat.system.plist" \
    "/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"
  do
    [ -e "$p" ] || [ -L "$p" ] || continue
    printf '%s\n' "$p"
  done

  launchctl print "gui/$UID_NUM/com.zot.macos-debloat" >/dev/null 2>&1 && printf '%s\n' "loaded login job: com.zot.macos-debloat"
  launchctl print "gui/$UID_NUM/com.zxt.macos-debloat" >/dev/null 2>&1 && printf '%s\n' "loaded login job: com.zxt.macos-debloat"
  launchctl print "system/com.zot.macos-debloat.system" >/dev/null 2>&1 && printf '%s\n' "loaded background job: com.zot.macos-debloat.system"
  launchctl print "system/com.zxt.macos-debloat.system" >/dev/null 2>&1 && printf '%s\n' "loaded background job: com.zxt.macos-debloat.system"
}

restore_legacy_state(){
  local state_file="$1" kind label domain
  [ -f "$state_file" ] || return 0
  while IFS='|' read -r kind label; do
    [ -n "${label:-}" ] || continue
    case "$kind" in
      user)
        domain="gui/$UID_NUM"
        launchctl enable "$domain/$label" >/dev/null 2>&1 || true
        ;;
      system)
        sudo launchctl enable "system/$label" >/dev/null 2>&1 || true
        ;;
    esac
  done < "$state_file"
}

restore_previous_changes(){
  local old

  for old in "$HOME/.macos-debloat/debloat" "$HOME/.zxt-macos-debloat/zxt"; do
    [ -x "$old" ] || continue
    echo "Restoring changes tracked by $(basename "$old")..."
    "$old" restore || true
  done

  restore_legacy_state "$HOME/.macos-debloat/state/disabled-services.txt"
  restore_legacy_state "$HOME/.zxt-macos-debloat/state/disabled-services.txt"

  if [ -f "$HOME/.macos-debloat/state/spotlight-changed.txt" ] || \
     [ -f "$HOME/.zxt-macos-debloat/state/spotlight-changed.txt" ]; then
    echo "Restoring Spotlight indexing..."
    sudo mdutil -i on / >/dev/null 2>&1 || true
  fi
}

remove_previous_autorun(){
  echo "Disabling and removing old Zot/ZXT login/background jobs..."

  launchctl bootout "gui/$UID_NUM/com.zot.macos-debloat" >/dev/null 2>&1 || true
  launchctl bootout "gui/$UID_NUM/com.zxt.macos-debloat" >/dev/null 2>&1 || true

  if [ -f "$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist" ]; then
    launchctl bootout "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist" >/dev/null 2>&1 || true
  fi
  if [ -f "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist" ]; then
    launchctl bootout "gui/$UID_NUM" "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist" >/dev/null 2>&1 || true
  fi

  if launchctl print system/com.zot.macos-debloat.system >/dev/null 2>&1 || \
     launchctl print system/com.zxt.macos-debloat.system >/dev/null 2>&1 || \
     [ -f "/Library/LaunchAgents/com.zot.macos-debloat.plist" ] || \
     [ -f "/Library/LaunchAgents/com.zxt.macos-debloat.plist" ] || \
     [ -f "/Library/LaunchDaemons/com.zot.macos-debloat.system.plist" ] || \
     [ -f "/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist" ]; then
    sudo launchctl bootout system/com.zot.macos-debloat.system >/dev/null 2>&1 || true
    sudo launchctl bootout system/com.zxt.macos-debloat.system >/dev/null 2>&1 || true
  fi

  rm -f \
    "$HOME/Library/LaunchAgents/com.zot.macos-debloat.plist" \
    "$HOME/Library/LaunchAgents/com.zxt.macos-debloat.plist"

  if [ -e "/Library/LaunchAgents/com.zot.macos-debloat.plist" ] || \
     [ -e "/Library/LaunchAgents/com.zxt.macos-debloat.plist" ] || \
     [ -e "/Library/LaunchDaemons/com.zot.macos-debloat.system.plist" ] || \
     [ -e "/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist" ]; then
    sudo rm -f \
      "/Library/LaunchAgents/com.zot.macos-debloat.plist" \
      "/Library/LaunchAgents/com.zxt.macos-debloat.plist" \
      "/Library/LaunchDaemons/com.zot.macos-debloat.system.plist" \
      "/Library/LaunchDaemons/com.zxt.macos-debloat.system.plist"
  fi
}

remove_previous_files(){
  local needs_sudo=0
  echo "Removing previous-version files..."

  rm -rf "$HOME/.macos-debloat" "$HOME/.zxt-macos-debloat"

  [ -e /usr/local/bin/debloat ] || [ -L /usr/local/bin/debloat ] && needs_sudo=1
  [ -e /usr/local/bin/zxt ] || [ -L /usr/local/bin/zxt ] && needs_sudo=1
  if [ "$needs_sudo" -eq 1 ]; then
    sudo rm -f /usr/local/bin/debloat /usr/local/bin/zxt
  fi
}

cleanup_previous_versions(){
  restore_previous_changes
  remove_previous_autorun
  remove_previous_files
  echo "Previous Zot/ZXT/debloat data and auto-run jobs were removed."
}

echo "Downloading Zot..."
for file in zot lib/common.sh lib/clean.sh lib/analyze.sh lib/system.sh lib/hub.sh presets/balanced.txt presets/aggressive.txt presets/siri.txt presets/apple-intelligence.txt; do
  fetch "$file"
done

bash -n "$TMP/zot" "$TMP"/lib/*.sh
chmod +x "$TMP/zot"

if [ "$FIRST_INSTALL" -eq 1 ]; then
  LEGACY_LIST="$(legacy_artifacts || true)"
  if [ -n "$LEGACY_LIST" ]; then
    printf '\nPrevious Zot/ZXT/debloat files were detected:\n'
    printf '%s\n' "$LEGACY_LIST" | sed 's/^/  - /'
    printf '\nThis can also restore old service/Spotlight changes and remove old auto-run/login/background jobs.\n'
    printf 'Would you like to delete all previous-version data and disable/remove its old background/login items? [y/N]: '
    IFS= read -r answer
    case "$answer" in
      y|Y|yes|YES)
        cleanup_previous_versions
        ;;
      *)
        echo "Previous-version files and jobs were left untouched."
        ;;
    esac
  fi
fi

mkdir -p "$PRESETS" "$LIB" "$STATE"

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

printf '\nZot installed.\n\nRun:\n  zot\n\nNo extra runtime, Python package, auto-login item, or background service was installed.\n'
