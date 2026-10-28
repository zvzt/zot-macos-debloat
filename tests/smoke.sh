#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for file in "$root/zot" "$root/install.sh" "$root"/lib/*.sh; do
  bash -n "$file"
done
echo "Bash syntax: OK"

if grep -Eq 'lib/full\.sh|full_maintenance' "$root/zot" "$root/install.sh" "$root/lib/hub.sh"; then
  echo "Old embedded cleanup reference remains." >&2
  exit 1
fi

temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT
STATE_DIR="$temp/state"
mkdir -p "$STATE_DIR"
pmset(){
  if [ "$1" = "-g" ] && [ "$2" = custom ]; then
    cat <<'DATA'
Battery Power:
 lowpowermode         1
 standby              1
AC Power:
 lowpowermode         0
 standby              1
DATA
  else
    echo "Unexpected pmset call in smoke test" >&2
    return 1
  fi
}
source "$root/lib/mode.sh"
[ "$(mode_value battery)" = 1 ]
[ "$(mode_value ac)" = 0 ]
mode_backup_original
[ -f "$MODE_ORIGINAL" ]
grep -qx 'battery=1' "$MODE_ORIGINAL"
grep -qx 'ac=0' "$MODE_ORIGINAL"
echo "Power settings parse and reversible snapshot: OK"
echo "All smoke tests passed."
