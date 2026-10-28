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
  --version) echo "Homebrew mock"; exit 0;;
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
have(){ command -v "$1" >/dev/null 2>&1; }
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
if install_app 2 >"$TMP/error.txt"; then
  echo "Expected failed Homebrew installation to fail" >&2
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

# Missing Homebrew, explicitly approved installer, resume selected app.
ZOT_TEST_BREW_AVAILABLE=0
zot_brew_path(){
  [ "$ZOT_TEST_BREW_AVAILABLE" = 1 ] && { printf '%s\n' "$TMP/mockbrew"; return 0; }
  return 1
}
zot_homebrew_can_prompt(){ return 0; }
zot_homebrew_download(){
  printf '#!/bin/bash\n# mocked official Homebrew installer\n' > "$1"
  printf 'download:official-homebrew\n' >> "$ZOT_TEST_LOG"
}
zot_homebrew_run(){
  printf 'run:official-homebrew\n' >> "$ZOT_TEST_LOG"
  ZOT_TEST_BREW_AVAILABLE=1
}
ZOT_TEST_BREW_RC=0
install_app 2 >"$TMP/bootstrap.txt"
grep -q '^download:official-homebrew$' "$ZOT_TEST_LOG"
grep -q '^run:official-homebrew$' "$ZOT_TEST_LOG"
grep -q '^record:homebrew-install:verified:0$' "$ZOT_TEST_LOG"
grep -q 'Homebrew installed and verified' "$TMP/bootstrap.txt"
grep -q '^brew:install --cask librewolf$' "$ZOT_TEST_LOG"

# Declining setup makes no changes.
ZOT_TEST_BREW_AVAILABLE=0
zot_homebrew_download(){ echo "should not download" >> "$ZOT_TEST_LOG"; return 1; }
confirm(){ return 1; }
if zot_install_homebrew >"$TMP/declined.txt"; then
  echo "Expected declined Homebrew setup to return without installing" >&2
  exit 1
fi
! grep -q 'should not download' "$ZOT_TEST_LOG"
confirm(){ return 0; }

# Empty official installer is never executed.
zot_homebrew_download(){ : > "$1"; return 0; }
zot_homebrew_run(){ printf 'should never execute\n' >> "$ZOT_TEST_LOG"; }
if zot_install_homebrew >"$TMP/failed-download.txt"; then
  echo "Expected empty download to fail" >&2
  exit 1
fi
grep -q 'download failed' "$TMP/failed-download.txt"
! grep -q 'should never execute' "$ZOT_TEST_LOG"

# Failure is not reported as success.
zot_homebrew_download(){ printf '#!/bin/bash\n' > "$1"; }
zot_homebrew_run(){ return 12; }
if zot_install_homebrew >"$TMP/failed-setup.txt"; then
  echo "Expected installer failure to be returned" >&2
  exit 1
fi
grep -q 'installation failed or was cancelled (exit 12)' "$TMP/failed-setup.txt"
grep -q '^record:homebrew-install:failed:12$' "$ZOT_TEST_LOG"

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
