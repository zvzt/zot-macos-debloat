#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash -n "$ROOT/zot"
bash -n "$ROOT"/lib/*.sh
bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"

ZOT_HOME="$ROOT" "$ROOT/zot" version | grep -Eq '^3\.1\.0$'
ZOT_HOME="$ROOT" "$ROOT/zot" --help | grep -q 'interactive terminal hub'
ZOT_HOME="$ROOT" "$ROOT/zot" --help | grep -q 'zot-status'
ZOT_HOME="$ROOT" "$ROOT/zot" --help | grep -q 'zot gui'

ln -sf "$ROOT/zot" "$TMP/zot-status"
STATUS_OUTPUT="$(ZOT_HOME="$ROOT" "$TMP/zot-status")"
grep -q 'Spotlight actual:' <<< "$STATUS_OUTPUT"
grep -q 'Zot auto-run/background helper: off' <<< "$STATUS_OUTPUT"

! grep -qi 'Python 3 is required' "$ROOT/install.sh"
! grep -qi 'pip install' "$ROOT/install.sh"
! grep -q 'RunAtLoad' "$ROOT/install.sh"
! grep -q 'launchctl bootstrap' "$ROOT/install.sh"
! grep -q '\[y/N\]' "$ROOT/install.sh"
grep -q '\[Y/N\]' "$ROOT/install.sh"
grep -q 'Please type Y or N' "$ROOT/install.sh"

! grep -q 'Communication' "$ROOT/lib/hub.sh"
! grep -q 'Media' "$ROOT/lib/hub.sh"
! grep -q 'Gaming' "$ROOT/lib/hub.sh"
! grep -q 'Google Chrome' "$ROOT/lib/hub.sh"
! grep -q 'Brave Browser' "$ROOT/lib/hub.sh"
! grep -q '"Arc"' "$ROOT/lib/hub.sh"
grep -q '"Zen"' "$ROOT/lib/hub.sh"
grep -q '"LibreWolf"' "$ROOT/lib/hub.sh"
grep -q '"Tor Browser"' "$ROOT/lib/hub.sh"
grep -q '"Xcode"' "$ROOT/lib/hub.sh"
grep -q '"Mousecape"' "$ROOT/lib/hub.sh"
grep -q '"BetterDisplay"' "$ROOT/lib/hub.sh"
grep -q '"OnyX"' "$ROOT/lib/hub.sh"
grep -q 'Color Customization' "$ROOT/lib/hub.sh"
grep -q 'Native Popup Hub' "$ROOT/lib/hub.sh"

! grep -q '/System/Library/LaunchAgents' "$ROOT/lib/system.sh"
grep -q 'Would you like to delete all previous-version data\|Delete all previous-version data' "$ROOT/install.sh"
grep -q '\.macos-debloat' "$ROOT/install.sh"
grep -q '\.zxt-macos-debloat' "$ROOT/install.sh"
grep -q '/usr/local/bin/debloat' "$ROOT/install.sh"
grep -q '/usr/local/bin/zxt' "$ROOT/install.sh"

grep -q 'Age-based Cache Clean' "$ROOT/lib/clean.sh"
grep -q 'Large Files' "$ROOT/lib/analyze.sh"
grep -q 'Restore Zot Changes' "$ROOT/lib/system.sh"

echo "Zot smoke tests passed."
