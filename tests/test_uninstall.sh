#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT
export HOME="$TEST_ROOT/user"
mkdir -p "$HOME/Applications" "$HOME/.Trash"
mkdir -p "$HOME/Library/Application Support/Firefox/Profiles/default-release"
mkdir -p "$HOME/Library/Application Support/FirefoxExperimental"
mkdir -p "$HOME/Library/Application Support/Firefox Nightly"
mkdir -p "$HOME/Library/Application Support/Code - Insiders"
mkdir -p "$HOME/Library/Application Support/SomeOtherApp"
mkdir -p "$HOME/Library/Application Support/Google/Chrome"
mkdir -p "$HOME/Library/Caches/org.mozilla.firefox"
mkdir -p "$HOME/Library/Containers/org.mozilla.firefox"
mkdir -p "$HOME/Library/Group Containers/group.org.mozilla.firefox"
mkdir -p "$HOME/Library/HTTPStorages/org.mozilla.firefox"
mkdir -p "$HOME/Library/Preferences"
mkdir -p "$HOME/Library/Logs"
printf 'history\n' > "$HOME/Library/Application Support/Firefox/Profiles/default-release/places.sqlite"
printf 'cookies\n' > "$HOME/Library/Application Support/Firefox/Profiles/default-release/cookies.sqlite"
printf 'preferences\n' > "$HOME/Library/Preferences/org.mozilla.firefox.plist"
printf 'extension\n' > "$HOME/Library/Preferences/org.mozilla.firefox.helper.plist"
printf 'unrelated\n' > "$HOME/Library/Application Support/FirefoxExperimental/keep.txt"
ln -s "$HOME/Library/Application Support/SomeOtherApp" "$HOME/Library/Caches/org.mozilla.firefox.symlink"

source "$ROOT/lib/analyze.sh"
APP_DATA_PATHS=() APP_SHARED_PATHS=()
app_scan_data "Firefox" "org.mozilla.firefox"
data_listing="$(printf '%s\n' "${APP_DATA_PATHS[@]}")"
shared_listing="$(printf '%s\n' "${APP_SHARED_PATHS[@]}")"
grep -Fxq "$HOME/Library/Application Support/Firefox" <<< "$data_listing"
grep -Fxq "$HOME/Library/Preferences/org.mozilla.firefox.plist" <<< "$data_listing"
grep -Fxq "$HOME/Library/Caches/org.mozilla.firefox" <<< "$data_listing"
grep -Fxq "$HOME/Library/Containers/org.mozilla.firefox" <<< "$data_listing"
grep -Fxq "$HOME/Library/Group Containers/group.org.mozilla.firefox" <<< "$shared_listing"
grep -Fxq "$HOME/Library/Preferences/org.mozilla.firefox.helper.plist" <<< "$shared_listing"
! grep -Fq 'FirefoxExperimental' <<< "$data_listing"
! grep -Fq 'Firefox Nightly' <<< "$data_listing"
! grep -Fq 'SomeOtherApp' <<< "$data_listing"
! grep -Fq 'symlink' <<< "$data_listing"
! grep -Fq 'group.org.mozilla.firefox' <<< "$data_listing"

app_scan_data "Visual Studio Code" "com.microsoft.VSCode"
! grep -Fq 'Code - Insiders' <<< "$(printf '%s\n' "${APP_DATA_PATHS[@]}")"

app_scan_data "Google Chrome" "com.google.Chrome"
grep -Fxq "$HOME/Library/Application Support/Google/Chrome" <<< "$(printf '%s\n' "${APP_DATA_PATHS[@]}")"
! grep -Fxq "$HOME/Library/Application Support/Google" <<< "$(printf '%s\n' "${APP_DATA_PATHS[@]}")"

# Simulate a reviewed uninstall without deleting anything in the actual runner home.
APP="$HOME/Applications/Firefox.app"
mkdir -p "$APP/Contents"
header(){ :; }
press_enter(){ :; }
confirm(){ case "$1" in *shared*) return 1;; *) return 0;; esac; }
record(){ printf 'record:%s:%s:%s\n' "$1" "$2" "$3" >> "$TEST_ROOT/actions"; }
path_bytes(){ echo 0; }
fmt_bytes(){ echo "$1 bytes"; }
BOLD='' ACCENT='' RESET='' YELLOW='' GREEN='' RED=''
trash_path(){
  local p="$1"
  mv "$p" "$HOME/.Trash/$(basename "$p")"
}
app_review_uninstall "$APP" Firefox org.mozilla.firefox > "$TEST_ROOT/uninstall.log"
[ ! -e "$APP" ]
[ ! -e "$HOME/Library/Application Support/Firefox" ]
[ ! -e "$HOME/Library/Preferences/org.mozilla.firefox.plist" ]
[ -e "$HOME/.Trash/Firefox.app" ]
[ -e "$HOME/.Trash/Firefox/Profiles/default-release/places.sqlite" ]
[ -e "$HOME/.Trash/Firefox/Profiles/default-release/cookies.sqlite" ]
[ -e "$HOME/Library/Group Containers/group.org.mozilla.firefox" ]
[ -e "$HOME/Library/Preferences/org.mozilla.firefox.helper.plist" ]
[ -e "$HOME/Library/Application Support/FirefoxExperimental/keep.txt" ]

# Declining confirmation must keep the app and all its data untouched.
mkdir -p "$HOME/Applications/Firefox.app"
mkdir -p "$HOME/Library/Application Support/Firefox"
confirm(){ return 1; }
app_review_uninstall "$HOME/Applications/Firefox.app" Firefox org.mozilla.firefox > "$TEST_ROOT/decline.log"
[ -d "$HOME/Applications/Firefox.app" ]
[ -d "$HOME/Library/Application Support/Firefox" ]
# macOS Bash 3.2 with set -u must handle apps with no matching data.
mkdir -p "$HOME/Applications/Opiumware.app"
app_scan_data Opiumware com.example.Opiumware
[ "${#APP_DATA_PATHS[@]}" -eq 0 ]
[ "${#APP_SHARED_PATHS[@]}" -eq 0 ]
confirm(){ return 0; }
app_review_uninstall "$HOME/Applications/Opiumware.app" Opiumware com.example.Opiumware > "$TEST_ROOT/empty-data.log"
grep -Fq 'No high-confidence user data found.' "$TEST_ROOT/empty-data.log"
[ ! -e "$HOME/Applications/Opiumware.app" ]
[ -e "$HOME/.Trash/Opiumware.app" ]

# Only potentially shared data: it must be listed but never removed by default.
mkdir -p "$HOME/Applications/SharedOnly.app"
mkdir -p "$HOME/Library/Group Containers/group.com.example.sharedonly"
confirm(){ case "$1" in *shared*) return 1;; *) return 0;; esac; }
app_scan_data SharedOnly com.example.sharedonly
[ "${#APP_DATA_PATHS[@]}" -eq 0 ]
[ "${#APP_SHARED_PATHS[@]}" -eq 1 ]
app_review_uninstall "$HOME/Applications/SharedOnly.app" SharedOnly com.example.sharedonly > "$TEST_ROOT/shared-only.log"
grep -Fq 'Possible shared data (1; not selected for removal)' "$TEST_ROOT/shared-only.log"
[ ! -e "$HOME/Applications/SharedOnly.app" ]
[ -e "$HOME/Library/Group Containers/group.com.example.sharedonly" ]

echo "Uninstaller safety and app data tests passed."
