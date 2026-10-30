scan_large_files(){
  LARGE_PATHS=(); LARGE_LABELS=()
  local root f size mtime age now
  now="$(date +%s)"
  for root in "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents" "$HOME/Movies"; do
    [ -d "$root" ] || continue
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      size="$(stat -f %z "$f" 2>/dev/null || echo 0)"; [ "$size" -ge 524288000 ] || continue
      mtime="$(stat -f %m "$f" 2>/dev/null || echo "$now")"; age=$(( (now-mtime)/86400 ))
      LARGE_PATHS+=("$f"); LARGE_LABELS+=("$(fmt_bytes "$size") · ${age}d · ${f#$HOME/}")
      [ ${#LARGE_PATHS[@]} -ge 100 ] && break 2
    done < <(find "$root" -type f -size +500M 2>/dev/null)
  done
}
scan_installers(){
  INSTALLER_PATHS=(); INSTALLER_LABELS=()
  local root f size
  for root in "$HOME/Downloads" "$HOME/Desktop" "$HOME/Library/Caches/Homebrew/downloads"; do
    [ -d "$root" ] || continue
    while IFS= read -r f; do
      [ -f "$f" ] || continue; size="$(stat -f %z "$f" 2>/dev/null || echo 0)"
      INSTALLER_PATHS+=("$f"); INSTALLER_LABELS+=("$(fmt_bytes "$size") · ${f#$HOME/}")
      [ ${#INSTALLER_PATHS[@]} -ge 100 ] && break 2
    done < <(find "$root" -maxdepth 4 -type f \( -iname '*.dmg' -o -iname '*.pkg' -o -iname '*.mpkg' -o -iname '*.iso' -o -iname '*.xip' \) 2>/dev/null)
  done
}
review_move_to_trash(){ local title="$1"; shift; local -a labels=("$@"); [ ${#labels[@]} -gt 0 ] || { header; echo "Nothing found."; press_enter; return; }; multi_menu "$title" "${labels[@]}" || return; }
large_files_screen(){
  header; printf '%bScanning common folders for files over 500 MB...%b\n' "$BOLD" "$RESET"; scan_large_files
  [ ${#LARGE_PATHS[@]} -gt 0 ] || { echo; echo "No files over 500 MB found in the scanned folders."; press_enter; return; }
  review_move_to_trash "Large Files · move selected to Trash" "${LARGE_LABELS[@]}"; [ -n "$MULTI_RESULT" ] || return
  header; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${LARGE_PATHS[$idx]}"; done; printf '\n'; confirm "Move selected files to Trash?" || return
  for idx in $MULTI_RESULT; do local b="$(stat -f %z "${LARGE_PATHS[$idx]}" 2>/dev/null || echo 0)"; trash_path "${LARGE_PATHS[$idx]}"; record trash "${LARGE_PATHS[$idx]}" "$b"; done
  printf '\n%bMoved to Trash.%b\n\n' "$GREEN" "$RESET"; press_enter
}
installers_screen(){
  header; printf '%bScanning for installer images/packages...%b\n' "$BOLD" "$RESET"; scan_installers
  [ ${#INSTALLER_PATHS[@]} -gt 0 ] || { echo; echo "No installers found."; press_enter; return; }
  review_move_to_trash "Installers · move selected to Trash" "${INSTALLER_LABELS[@]}"; [ -n "$MULTI_RESULT" ] || return
  header; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${INSTALLER_PATHS[$idx]}"; done; printf '\n'; confirm "Move selected installers to Trash?" || return
  for idx in $MULTI_RESULT; do local b="$(stat -f %z "${INSTALLER_PATHS[$idx]}" 2>/dev/null || echo 0)"; trash_path "${INSTALLER_PATHS[$idx]}"; record trash "installer:${INSTALLER_PATHS[$idx]}" "$b"; done
  printf '\n%bInstallers moved to Trash.%b\n\n' "$GREEN" "$RESET"; press_enter
}
backup_screen(){
  local root="$HOME/Library/Application Support/MobileSync/Backup"
  [ -d "$root" ] || { header; echo "No local iPhone/iPad backups found."; press_enter; return; }
  local -a paths labels; paths=(); labels=(); local d name product size datev info
  for d in "$root"/*; do
    [ -d "$d" ] || continue; info="$d/Info.plist"; name="Backup $(basename "$d" | cut -c1-10)"; product=""
    if [ -f "$info" ]; then name="$(/usr/libexec/PlistBuddy -c 'Print :Device Name' "$info" 2>/dev/null || echo "$name")"; product="$(/usr/libexec/PlistBuddy -c 'Print :Product Type' "$info" 2>/dev/null || true)"; fi
    size="$(path_bytes "$d")"; datev="$(stat -f '%Sm' -t '%Y-%m-%d' "$d" 2>/dev/null || echo unknown)"
    paths+=("$d"); labels+=("$name ${product:+· $product} · $(fmt_bytes "$size") · $datev")
  done
  [ ${#paths[@]} -gt 0 ] || { header; echo "No local backups found."; press_enter; return; }
  multi_menu "Device Backups · move selected to Trash" "${labels[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${labels[$idx]}"; done; printf '\n'; confirm "Move selected device backups to Trash?" || return
  for idx in $MULTI_RESULT; do local b="$(path_bytes "${paths[$idx]}")"; trash_path "${paths[$idx]}"; record trash "device-backup:${paths[$idx]}" "$b"; done
  printf '\n%bBackups moved to Trash.%b\n\n' "$GREEN" "$RESET"; press_enter
}
folder_usage_screen(){
  header; printf '%bCalculating top-level home folder usage...%b\n\n' "$BOLD" "$RESET"
  local p b
  for p in "$HOME"/* "$HOME/Library"/*; do
    [ -e "$p" ] || continue
    case "$p" in "$HOME/Library/Caches"|"$HOME/Library/Containers"|"$HOME/Library/Application Support"|"$HOME/Downloads"|"$HOME/Documents"|"$HOME/Desktop"|"$HOME/Movies"|"$HOME/Pictures"|"$HOME/Music") ;; *) continue;; esac
    b="$(path_bytes "$p")"; printf '  %10s  %s\n' "$(fmt_bytes "$b")" "${p#$HOME/}"
  done | sort -hr
  printf '\n%bRead-only view.%b\n\n' "$GRAY" "$RESET"; press_enter
}
analyze_menu(){ while :; do menu "Analyze Storage" "Storage Overview — major user folders" "Large Files — review files over 500 MB" "Old Installers — DMG, PKG, XIP, ISO" "iPhone / iPad Backups — local device backups" "Project Artifacts — rebuildable developer folders" "Back — return to the hub"; case "$MENU_RESULT" in 0) folder_usage_screen;; 1) large_files_screen;; 2) installers_screen;; 3) backup_screen;; 4) purge_projects;; *) return;; esac; done; }
# Uninstall only after reviewing app identity and explicitly matched user data.
# App profiles often include history, cookies, sessions, extensions and credentials.
# Shared/cloud/system data are not implicitly removed.
list_apps(){
  APP_PATHS=(); APP_LABELS=(); APP_BUNDLES=(); APP_NAMES=()
  local app name bundle size
  while IFS= read -r app; do
    [ -d "$app" ] && [ ! -L "$app" ] || continue
    name="$(basename "$app" .app)"
    bundle=""
    if [ -f "$app/Contents/Info.plist" ]; then
      bundle="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
    fi
    if [ -z "$bundle" ]; then
      bundle="$(mdls -name kMDItemCFBundleIdentifier -raw "$app" 2>/dev/null || true)"
    fi
    [ "$bundle" = '(null)' ] && bundle=""
    size="$(path_bytes "$app")"
    APP_PATHS+=("$app"); APP_NAMES+=("$name"); APP_BUNDLES+=("$bundle")
    APP_LABELS+=("$name · $(fmt_bytes "$size")")
    [ "${#APP_PATHS[@]}" -ge 120 ] && break
  done < <(find /Applications "$HOME/Applications" -maxdepth 2 -type d -name '*.app' 2>/dev/null | sort -f)
}

app_lower(){ printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }

app_valid_bundle(){
  [ -n "$1" ] || return 1
  [[ "$1" =~ ^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$ ]]
}

app_name_matches(){
  local leaf candidate
  leaf="$(app_lower "$1")"; candidate="$(app_lower "$2")"
  [ -n "$leaf" ] && [ -n "$candidate" ] || return 1
  # Exact app names or filenames belonging to that exact name.
  # Prefixes such as "Firefox Nightly" or "Code - Insiders"
  # are NOT automatically considered the same app.
  case "$leaf" in
    "$candidate"|"$candidate.app"|"$candidate.plist"|"$candidate.savedstate"|\
    "$candidate.binarycookies"|"$candidate.log"|"$candidate.db"|"$candidate.sqlite")
      return 0;;
    *) return 1;;
  esac
}

# Restrict all data matches to known per-user Library subfolders.
app_safe_data_path(){
  local p="$1" root
  [ -e "$p" ] && [ ! -L "$p" ] || return 1
  case "$p" in
    "$HOME/Library/Application Support/"*|"$HOME/Library/Caches/"*|"$HOME/Library/Preferences/"*|\
    "$HOME/Library/Saved Application State/"*|"$HOME/Library/Containers/"*|\
    "$HOME/Library/Group Containers/"*|"$HOME/Library/HTTPStorages/"*|"$HOME/Library/WebKit/"*|\
    "$HOME/Library/Cookies/"*|"$HOME/Library/Logs/"*|\
    "$HOME/Library/Application Scripts/"*|"$HOME/Library/LaunchAgents/"*) ;;
    *) return 1;;
  esac
  [ ! -L "$(dirname "$p")" ] || return 1
  # Never move a complete category, just its child entries.
  [ "$(dirname "$p")" != "$HOME/Library" ] || return 1
  return 0
}

app_add_data(){
  local path="$1" kind="$2" existing
  app_safe_data_path "$path" || return 0
  # Guard empty arrays for macOS Bash 3.2 running with set -u.
  for existing in "${APP_DATA_PATHS[@]+"${APP_DATA_PATHS[@]}"}" "${APP_SHARED_PATHS[@]+"${APP_SHARED_PATHS[@]}"}"; do
    [ "$existing" = "$path" ] && return 0
    case "$path" in "$existing/"*) return 0;; esac
  done
  if [ "$kind" = shared ]; then
    APP_SHARED_PATHS+=("$path")
  else
    APP_DATA_PATHS+=("$path")
  fi
}

app_data_name_alias(){
  local name
  name="$(app_lower "$1")"
  case "$name" in
    'google chrome') printf 'Chrome\n';;
    'google chrome canary') printf 'Chrome Canary\n';;
    'brave browser') printf 'Brave-Browser\n';;
    'zen browser') printf 'zen\n';;
    'opera') printf 'Opera Stable\n';;
    'visual studio code') printf 'Code\n';;
    'microsoft edge') printf 'Edge\n';;
    'firefox developer edition') printf 'Firefox Developer Edition\n';;
    *) printf '\n';;
  esac
}

app_candidate_kind(){
  local path="$1" name="$2" bundle="$3" alias="$4"
  local leaf low id group
  leaf="$(basename "$path")"; low="$(app_lower "$leaf")"
  id="$(app_lower "$bundle")"
  if [ -n "$id" ]; then
    case "$low" in
      "$id"|"$id.plist"|"$id.savedstate"|"$id.binarycookies") echo exact; return;;
      # Suffixes might belong to separate extensions/apps; manual review.
      "$id".*|"$id"-*|"$id"_*) echo shared; return;;
      "group.$id"|"group.$id."*) echo shared; return;;
    esac
  fi
  # Directory names (e.g. Firefox and its profile folder) are safe when
  # the entire component identifies the selected app.
  if app_name_matches "$leaf" "$name"; then
    echo exact; return
  fi
  if [ -n "$alias" ] && app_name_matches "$leaf" "$alias"; then
    echo exact; return
  fi
  echo none
}

app_scan_data(){
  local name="$1" bundle="$2" alias root item child kind rel
  local -a roots
  APP_DATA_PATHS=(); APP_SHARED_PATHS=()
  alias="$(app_data_name_alias "$name")"
  if ! app_valid_bundle "$bundle"; then bundle=""; fi
  roots=(
    "$HOME/Library/Application Support"
    "$HOME/Library/Caches"
    "$HOME/Library/Preferences"
    "$HOME/Library/Saved Application State"
    "$HOME/Library/Containers"
    "$HOME/Library/Group Containers"
    "$HOME/Library/HTTPStorages"
    "$HOME/Library/WebKit"
    "$HOME/Library/Cookies"
    "$HOME/Library/Logs"
    "$HOME/Library/Application Scripts"
    "$HOME/Library/LaunchAgents"
  )
  for root in "${roots[@]}"; do
    [ -d "$root" ] && [ ! -L "$root" ] || continue
    for item in "$root"/*; do
      [ -e "$item" ] && [ ! -L "$item" ] || continue
      kind="$(app_candidate_kind "$item" "$name" "$bundle" "$alias")"
      # Every Group Container is potentially shared across multiple apps.
      case "$item" in "$HOME/Library/Group Containers/"*) [ "$kind" != none ] && kind=shared;; esac
      if [ "$kind" != none ]; then
        app_add_data "$item" "$kind"
      elif [ -d "$item" ]; then
        # Only scan second-level names under vendor folders, not arbitrary
        # profile contents. This catches e.g. Google/Chrome and Mozilla/Firefox.
        case "$root" in
          "$HOME/Library/Application Support"|"$HOME/Library/Caches"|"$HOME/Library/Preferences")
            for child in "$item"/*; do
              [ -e "$child" ] && [ ! -L "$child" ] || continue
              kind="$(app_candidate_kind "$child" "$name" "$bundle" "$alias")"
              [ "$kind" = none ] || app_add_data "$child" "$kind"
            done;;
        esac
      fi
    done
  done
}

app_move_to_trash_checked(){
  local path="$1" verb="$2"
  [ -e "$path" ] && [ ! -L "$path" ] || return 1
  trash_path "$path"
  if [ -e "$path" ]; then
    printf '%bCould not move to Trash: %s%b\n' "$RED" "$path" "$RESET"
    record uninstall-failed "$path" 1
    return 1
  fi
  record "$verb" "$path" 0
  return 0
}

app_review_uninstall(){
  local app="$1" name="$2" bundle="$3" path count shared_count success=0 fail=0
  app_scan_data "$name" "$bundle"
  count="${#APP_DATA_PATHS[@]}"
  shared_count="${#APP_SHARED_PATHS[@]}"
  header
  printf '%b◆ Uninstall %s and its data%b\n\n' "$BOLD$ACCENT" "$name" "$RESET"
  printf 'Application: %s\nBundle ID: %s\n' "$app" "${bundle:-unknown}"
  printf '\nMatched app data (%s paths):\n' "$count"
  if [ "$count" -eq 0 ]; then
    printf '  No high-confidence user data found.\n'
  else
    for path in "${APP_DATA_PATHS[@]+"${APP_DATA_PATHS[@]}"}"; do
      printf '  %s · %s\n' "${path#$HOME/}" "$(fmt_bytes "$(path_bytes "$path")")"
    done
  fi
  if [ "$shared_count" -gt 0 ]; then
    printf '\n%bPossible shared data (%s; not selected for removal):%b\n' "$YELLOW" "$shared_count" "$RESET"
    for path in "${APP_SHARED_PATHS[@]+"${APP_SHARED_PATHS[@]}"}"; do
      printf '  %s\n' "${path#$HOME/}"
    done
  fi
  printf '\nApp profiles may contain browsing history, cookies, sessions, extensions and locally saved data.\n'
  printf 'Files are moved to Trash, NOT securely erased. Cloud data, Keychain items,\n'
  printf 'data belonging to other users and system-wide files are not removed.\n'
  printf 'Quit the application before proceeding to prevent it recreating data.\n\n'
  confirm "Move $name AND all listed matched data to Trash?" || return 0
  # Prevent deletion when no longer in approved user/app paths.
  case "$app" in /Applications/*.app|/Applications/*/*.app|"$HOME/Applications/"*.app|"$HOME/Applications/"*/*.app) ;;
    *) echo "App location not permitted. Nothing removed."; return 1;; esac
  [ -d "$app" ] && [ ! -L "$app" ] || { echo "App no longer exists; nothing removed."; return 1; }
  app_move_to_trash_checked "$app" uninstall-app || {
    printf '\nApplication could not be moved. Data has been left untouched.\n'
    press_enter; return 1
  }
  success=$((success+1))
  for path in "${APP_DATA_PATHS[@]+"${APP_DATA_PATHS[@]}"}"; do
    if app_safe_data_path "$path" && app_move_to_trash_checked "$path" uninstall-data; then
      success=$((success+1))
    else
      fail=$((fail+1))
    fi
  done
  if [ "$shared_count" -gt 0 ]; then
    printf '\nShared candidates can affect other apps. They are not removed by default.\n'
    if confirm "Also move the listed possible shared data to Trash?"; then
      for path in "${APP_SHARED_PATHS[@]+"${APP_SHARED_PATHS[@]}"}"; do
        if app_safe_data_path "$path" && app_move_to_trash_checked "$path" uninstall-shared; then
          success=$((success+1))
        else
          fail=$((fail+1))
        fi
      done
    fi
  fi
  printf '\n%bMoved %s items to Trash.%b' "$GREEN" "$success" "$RESET"
  [ "$fail" -eq 0 ] || printf '\n%b%s items failed; review the errors above.%b' "$YELLOW" "$fail" "$RESET"
  printf '\nEmpty Trash manually only after verifying nothing else needs those files.\n\n'
  press_enter
}

apps_screen(){
  header
  printf '%bScanning installed applications...%b\n' "$BOLD" "$RESET"
  list_apps
  [ "${#APP_PATHS[@]}" -gt 0 ] || {
    echo; echo "No applications found."; press_enter; return
  }
  multi_menu "Uninstall Apps · Space select, Enter review" "${APP_LABELS[@]}" || return
  [ -n "$MULTI_RESULT" ] || return
  local idx
  for idx in $MULTI_RESULT; do
    app_review_uninstall "${APP_PATHS[$idx]}" "${APP_NAMES[$idx]}" "${APP_BUNDLES[$idx]}"
  done
}
