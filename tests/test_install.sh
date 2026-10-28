#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME/Applications"
export ZOT_TEST_LOG="$TMP/operations.log"
: > "$ZOT_TEST_LOG"
ZOT_TEST_BREW_RECEIPT=0
ZOT_TEST_BREW_RC=0
export ZOT_TEST_BREW_RECEIPT ZOT_TEST_BREW_RC

cat > "$TMP/mockbrew" <<'BREW'
#!/bin/bash
printf 'brew:%s\n' "$*" >> "$ZOT_TEST_LOG"
case "$1" in
  list) [ "${ZOT_TEST_BREW_RECEIPT:-0}" = 1 ];;
  --version) echo "Homebrew mock"; exit 0;;
  install|reinstall)
    [ "${ZOT_TEST_BREW_RC:-0}" = 0 ] || exit "$ZOT_TEST_BREW_RC"
    case "${*: -1}" in
      librewolf) mkdir -p "$HOME/Applications/LibreWolf.app";;
      tor-browser) mkdir -p "$HOME/Applications/Tor Browser.app";;
    esac
    exit 0;;
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

# A valid receipt is not proof that the actual Tor Browser.app is installed.
ZOT_TEST_BREW_RECEIPT=1
[ "$(catalog_install_state 3)" = repair ]
! catalog_installed 3
install_app 3 > "$TMP/tor-repair.txt"
grep -q '^brew:reinstall --cask tor-browser$' "$ZOT_TEST_LOG"
grep -q '^record:reinstall:Tor Browser:0$' "$ZOT_TEST_LOG"
[ -d "$HOME/Applications/Tor Browser.app" ]
[ "$(catalog_install_state 3)" = installed ]
install_app 3 > "$TMP/tor-installed.txt"
grep -q 'app is present; already installed' "$TMP/tor-installed.txt"
# Existing Tor profile data is preserved.
mkdir -p "$HOME/Library/Application Support/TorBrowser"
printf 'profile\n' > "$HOME/Library/Application Support/TorBrowser/saved.txt"
[ -f "$HOME/Library/Application Support/TorBrowser/saved.txt" ]

# If no Homebrew cask receipt and no app exists, use install, not reinstall.
ZOT_TEST_BREW_RECEIPT=0
[ "$(catalog_install_state 2)" = missing ]
install_app 2 > "$TMP/new-install.txt"
grep -q '^brew:install --cask librewolf$' "$ZOT_TEST_LOG"
grep -q '^record:install:LibreWolf:0$' "$ZOT_TEST_LOG"
[ -d "$HOME/Applications/LibreWolf.app" ]

# A non-zero Homebrew exit cannot be reported as a successful install.
rmdir "$HOME/Applications/LibreWolf.app"
ZOT_TEST_BREW_RC=17
if install_app 2 > "$TMP/error.txt"; then
  echo "Expected failed Homebrew install to return non-zero" >&2
  exit 1
fi
grep -q 'failed (exit code 17)' "$TMP/error.txt"
grep -q '^record:install:LibreWolf:17$' "$ZOT_TEST_LOG"

# A successful Homebrew exit without an app must be reported as unverified.
ZOT_TEST_BREW_RC=0
rmdir "$HOME/Applications/Tor Browser.app"
zot_brew_path(){ printf '%s\n' "$TMP/mockbrew"; }
[ "$(catalog_install_state 3)" = missing ] || [ "$(catalog_install_state 3)" = repair ]

# Without brew, the official app website opens instead.
zot_brew_path(){ return 1; }
install_app 2 > "$TMP/fallback.txt"
grep -q '^open:https://librewolf.net/installation/macos/$' "$ZOT_TEST_LOG"
grep -q 'Official download page opened' "$TMP/fallback.txt"
install_app 5 > "$TMP/mousecape.txt"
grep -q '^open:https://github.com/alexzielenski/Mousecape/releases$' "$ZOT_TEST_LOG"

# Missing brew: install the official script with user confirmation, then app.
ZOT_TEST_BREW_AVAILABLE=0
zot_brew_path(){
  [ "$ZOT_TEST_BREW_AVAILABLE" = 1 ] && { printf '%s\n' "$TMP/mockbrew"; return 0; }
  return 1
}
zot_homebrew_can_prompt(){ return 0; }
zot_homebrew_download(){
  printf '#!/bin/bash\n# mocked installer\n' > "$1"
  printf 'download:official-homebrew\n' >> "$ZOT_TEST_LOG"
}
zot_homebrew_run(){
  printf 'run:official-homebrew\n' >> "$ZOT_TEST_LOG"
  ZOT_TEST_BREW_AVAILABLE=1
}
ZOT_TEST_BREW_RC=0
install_app 2 > "$TMP/bootstrap.txt"
grep -q '^download:official-homebrew$' "$ZOT_TEST_LOG"
grep -q '^record:homebrew-install:verified:0$' "$ZOT_TEST_LOG"
grep -q 'Homebrew installed and verified' "$TMP/bootstrap.txt"

# Declining Homebrew leaves things unchanged.
ZOT_TEST_BREW_AVAILABLE=0
zot_homebrew_download(){ echo 'should not download' >> "$ZOT_TEST_LOG"; return 1; }
confirm(){ return 1; }
if zot_install_homebrew > "$TMP/declined.txt"; then exit 1; fi
! grep -q 'should not download' "$ZOT_TEST_LOG"
confirm(){ return 0; }

# Failed download must never execute an installer.
zot_homebrew_download(){ : > "$1"; return 0; }
zot_homebrew_run(){ printf 'should not run\n' >> "$ZOT_TEST_LOG"; }
if zot_install_homebrew > "$TMP/failed-download.txt"; then exit 1; fi
grep -q 'download failed' "$TMP/failed-download.txt"
! grep -q 'should not run' "$ZOT_TEST_LOG"

# Homebrew installer failure is not a successful bootstrap.
zot_homebrew_download(){ printf '#!/bin/bash\n' > "$1"; }
zot_homebrew_run(){ return 12; }
if zot_install_homebrew > "$TMP/failed-setup.txt"; then exit 1; fi
grep -q 'installation failed or was cancelled (exit 12)' "$TMP/failed-setup.txt"
grep -q '^record:homebrew-install:failed:12$' "$ZOT_TEST_LOG"

# Enter chooses the highlighted item; Back returns to the category list.
menu_calls=0
menu(){
  menu_calls=$((menu_calls+1))
  if [ "$menu_calls" -eq 1 ]; then MENU_RESULT=1
  else MENU_RESULT=4
  fi
}
install_app(){ printf 'picked:%s\n' "$1" >> "$ZOT_TEST_LOG"; }
catalog_install_state(){ printf 'missing\n'; }
install_group Browsers
grep -q '^picked:1$' "$ZOT_TEST_LOG"

echo "App installer and Tor Browser repair tests passed."
