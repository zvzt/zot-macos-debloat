#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash -n "$ROOT/zot"
bash -n "$ROOT"/lib/*.sh
bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"

ZOT_HOME="$ROOT" "$ROOT/zot" version | grep -Eq '^3\.2\.0$'
HELP_OUTPUT="$(ZOT_HOME="$ROOT" "$ROOT/zot" --help)"
grep -q 'interactive terminal hub' <<< "$HELP_OUTPUT"
grep -q 'zot-status' <<< "$HELP_OUTPUT"
grep -q 'zot-login' <<< "$HELP_OUTPUT"
grep -q 'zot login' <<< "$HELP_OUTPUT"

ln -sf "$ROOT/zot" "$TMP/zot-status"
STATUS_OUTPUT="$(ZOT_HOME="$ROOT" "$TMP/zot-status")"
grep -q 'Spotlight actual:' <<< "$STATUS_OUTPUT"
grep -q 'Login Tweaks Auto Apply:' <<< "$STATUS_OUTPUT"
grep -q 'Login Cleaning Auto Run:' <<< "$STATUS_OUTPUT"
grep -q 'Persistent background process: none' <<< "$STATUS_OUTPUT"

! grep -qi 'Python 3 is required' "$ROOT/install.sh"
! grep -qi 'pip install' "$ROOT/install.sh"
! grep -q 'RunAtLoad' "$ROOT/install.sh"
! grep -q 'launchctl bootstrap' "$ROOT/install.sh"
! grep -q '\[y/N\]' "$ROOT/install.sh"
grep -q '\[Y/N\]' "$ROOT/install.sh"
grep -q 'Please type Y or N' "$ROOT/install.sh"
grep -q 'zot-login' "$ROOT/install.sh"
grep -q 'lib/login.sh' "$ROOT/install.sh"

grep -q 'Login Items' "$ROOT/lib/hub.sh"
grep -q 'Tweaks — choose what Zot reapplies at boot/login' "$ROOT/lib/login.sh"
grep -q 'Cleaning — choose what Zot cleans each login' "$ROOT/lib/login.sh"
grep -q 'Enable Auto Apply for these tweaks at login?' "$ROOT/lib/login.sh"
grep -q 'Enable automatic cleaning at login?' "$ROOT/lib/login.sh"
grep -q 'Run Tweaks Now' "$ROOT/lib/login.sh"
grep -q 'Run Cleaning Now' "$ROOT/lib/login.sh"
grep -q 'com.zot.login.tweaks' "$ROOT/lib/login.sh"
grep -q 'com.zot.login.cleaning' "$ROOT/lib/login.sh"
grep -q 'com.zot.login.system-tweaks' "$ROOT/lib/login.sh"
grep -q '<key>RunAtLoad</key>' "$ROOT/lib/login.sh"
! grep -q '<key>KeepAlive</key>' "$ROOT/lib/login.sh"
grep -q 'root:wheel.*LOGIN_SYSTEM_SCRIPT' "$ROOT/lib/login.sh"
grep -q 'chmod 700.*LOGIN_SYSTEM_SCRIPT' "$ROOT/lib/login.sh"
! grep -q 'login-run-system' "$ROOT/lib/login.sh"
! grep -q 'login-run-system' "$ROOT/lib/hub.sh"

! grep -q 'Communication' "$ROOT/lib/hub.sh"
! grep -q 'Media' "$ROOT/lib/hub.sh"
! grep -q 'Gaming' "$ROOT/lib/hub.sh"
! grep -q 'Google Chrome' "$ROOT/lib/hub.sh"
! grep -q 'Brave Browser' "$ROOT/lib/hub.sh"
! grep -q '"Arc"' "$ROOT/lib/hub.sh"
grep -q '"Zen"' "$ROOT/lib/hub.sh"
grep -q '"LibreWolf"' "$ROOT/lib/hub.sh"
grep -q '"Tor Browser"' "$ROOT/lib/hub.sh"

! grep -q '/System/Library/LaunchAgents' "$ROOT/lib/system.sh"
grep -q 'Delete all previous-version data' "$ROOT/install.sh"
grep -q '\.macos-debloat' "$ROOT/install.sh"
grep -q '\.zxt-macos-debloat' "$ROOT/install.sh"

grep -q 'Age-based Cache Clean' "$ROOT/lib/clean.sh"
grep -q 'Large Files' "$ROOT/lib/analyze.sh"
grep -q 'Restore Zot Changes' "$ROOT/lib/system.sh"

echo "Zot smoke tests passed."
