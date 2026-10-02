#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash -n "$ROOT/zot"
bash -n "$ROOT"/lib/*.sh
bash -n "$ROOT/install.sh"
bash -n "$ROOT/uninstall.sh"

ZOT_HOME="$ROOT" "$ROOT/zot" version | grep -Eq '^3\.0\.0$'
ZOT_HOME="$ROOT" "$ROOT/zot" --help | grep -q 'Open the interactive hub'
ZOT_HOME="$ROOT" "$ROOT/zot" --help | grep -q 'zot install'

! grep -qi 'Python 3 is required' "$ROOT/install.sh"
! grep -qi 'pip install' "$ROOT/install.sh"
! grep -q 'RunAtLoad' "$ROOT/install.sh"
! grep -q 'launchctl bootstrap' "$ROOT/install.sh"
! grep -q '/System/Library/LaunchAgents' "$ROOT/lib/system.sh"

grep -q 'Would you like to delete all previous-version data' "$ROOT/install.sh"
grep -q '\.macos-debloat' "$ROOT/install.sh"
grep -q '\.zxt-macos-debloat' "$ROOT/install.sh"
grep -q '/usr/local/bin/debloat' "$ROOT/install.sh"
grep -q '/usr/local/bin/zxt' "$ROOT/install.sh"
grep -q 'com.zot.macos-debloat' "$ROOT/install.sh"
grep -q 'com.zxt.macos-debloat' "$ROOT/install.sh"

grep -q 'Homebrew is not installed' "$ROOT/lib/hub.sh"
grep -q 'Age-based Cache Clean' "$ROOT/lib/clean.sh"
grep -q 'Large Files' "$ROOT/lib/analyze.sh"
grep -q 'Restore Items Disabled by Zot' "$ROOT/lib/system.sh"

echo "Zot smoke tests passed."
