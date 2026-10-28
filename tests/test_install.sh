#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export ZOT_TEST_LOG="$TMP/operations.log"
: > "$ZOT_TEST_LOG"

cat > "$TMP/mockbrew" <<'BREW'
#!/bin/bash
printf 'brew:%s\n' "$*" >> "$ZOT_TEST_LOG"
case "$1" in
  list) exit 1;;
  install) exit "${ZOT_TEST_BREW_RC:-0}";;
  *) exit 1;;
esac
BREW
chmod +x "$TMP/mockbrew"

source "$ROOT/lib/hub.sh"
ESC='' BOLD='' ACCENT='' GREEN='' RED='' YELLOW='' RESET=''
header(){ :; }
press_enter(){ :; }
confirm(){ return 0; }
record(){ printf 'record:%s:%s:%s\n' "$1" "$2" "$3" >> "$ZOT_TEST_LOG"; }
open(){ printf 'open:%s\n' "$1" >> "$ZOT_TEST_LOG"; }
zot_brew_path(){ printf '%s\n' "$TMP/mockbrew"; }

catalog_init
[ "${#CAT_NAMES[@]}" -eq "${#CAT_PKGS[@]}" ]
[ "${#CAT_NAMES[@]}" -eq "${#CAT_TYPES[@]}" ]
[ "${#CAT_NAMES[@]}" -eq "${#CAT_URLS[@]}" ]
[ "${#CAT_NAMES[@]}" -eq "${#CAT_GROUPS[@]}" ]
[ "${#CAT_NAMES[@]}" -eq "${#CAT_APP_NAMES[@]}" ]

ZOT_TEST_BREW_RC=0
export ZOT_TEST_BREW_RC
install_app 2 >/dev/null
grep -q '^brew:install --cask librewolf$' "$ZOT_TEST_LOG"
grep -q '^record:install:LibreWolf:0$' "$ZOT_TEST_LOG"

ZOT_TEST_BREW_RC=17
export ZOT_TEST_BREW_RC
if install_app 2 >"$TMP/error.txt"; then
  echo 'Expected failed Homebrew installation to fail' >&2
  exit 1
fi
grep -q 'Install failed (exit code 17)' "$TMP/error.txt"
grep -q '^record:install:LibreWolf:17$' "$ZOT_TEST_LOG"

zot_brew_path(){ return 1; }
install_app 2 >"$TMP/fallback.txt"
grep -q '^open:https://librewolf.net/installation/macos/$' "$ZOT_TEST_LOG"
grep -q 'Official download page opened' "$TMP/fallback.txt"
grep -q '^record:open-download:LibreWolf:0$' "$ZOT_TEST_LOG"

install_app 5 >"$TMP/mousecape.txt"
grep -q '^open:https://github.com/alexzielenski/Mousecape/releases$' "$ZOT_TEST_LOG"
grep -q '^record:open-download:Mousecape:0$' "$ZOT_TEST_LOG"

menu_calls=0
menu(){
  menu_calls=$((menu_calls+1))
  if [ "$menu_calls" -eq 1 ]; then MENU_RESULT=1
  else MENU_RESULT=4
  fi
}
install_app(){ printf 'picked:%s\n' "$1" >> "$ZOT_TEST_LOG"; }
catalog_installed(){ return 1; }
install_group Browsers
grep -q '^picked:1$' "$ZOT_TEST_LOG"

echo "App installer behavior tests passed."
