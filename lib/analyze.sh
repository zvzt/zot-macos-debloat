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
analyze_menu(){ while :; do menu "Analyze Storage" "Storage Overview" "Large Files (500MB+)" "Old Installers" "iPhone / iPad Backups" "Project Artifacts" "Back"; case "$MENU_RESULT" in 0) folder_usage_screen;; 1) large_files_screen;; 2) installers_screen;; 3) backup_screen;; 4) purge_projects;; *) return;; esac; done; }
list_apps(){
  APP_PATHS=(); APP_LABELS=(); APP_BUNDLES=(); APP_NAMES=(); local app name bundle size
  while IFS= read -r app; do
    [ -d "$app" ] || continue; name="$(basename "$app" .app)"
    bundle="$(mdls -name kMDItemCFBundleIdentifier -raw "$app" 2>/dev/null || true)"; [ "$bundle" = '(null)' ] && bundle=""
    size="$(path_bytes "$app")"; APP_PATHS+=("$app"); APP_NAMES+=("$name"); APP_BUNDLES+=("$bundle"); APP_LABELS+=("$name · $(fmt_bytes "$size")"); [ ${#APP_PATHS[@]} -ge 120 ] && break
  done < <(find /Applications "$HOME/Applications" -maxdepth 2 -type d -name '*.app' 2>/dev/null | sort -f)
}
app_leftovers(){
  local name="$1" bundle="$2" p; LEFTOVER_PATHS=(); LEFTOVER_LABELS=(); [ -n "$bundle" ] || return 0
  for p in "$HOME/Library/Caches/$bundle" "$HOME/Library/Preferences/$bundle.plist" "$HOME/Library/Saved Application State/$bundle.savedState" "$HOME/Library/Containers/$bundle" "$HOME/Library/HTTPStorages/$bundle" "$HOME/Library/WebKit/$bundle" "$HOME/Library/Application Support/$name" "$HOME/Library/Logs/$name"; do
    [ -e "$p" ] || continue; LEFTOVER_PATHS+=("$p"); LEFTOVER_LABELS+=("${p#$HOME/} · $(fmt_bytes "$(path_bytes "$p")")")
  done
}
apps_screen(){
  header; printf '%bScanning Applications...%b\n' "$BOLD" "$RESET"; list_apps
  [ ${#APP_PATHS[@]} -gt 0 ] || { echo; echo "No applications found."; press_enter; return; }
  multi_menu "Apps · select applications to uninstall" "${APP_LABELS[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header; printf '%bUninstall review%b\n\n' "$BOLD" "$RESET"; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${APP_PATHS[$idx]}"; done
  printf '\nApps are moved to Trash. Exact bundle-ID leftovers can also be reviewed.\n\n'; confirm "Continue with selected apps?" || return
  for idx in $MULTI_RESULT; do
    local app="${APP_PATHS[$idx]}" name="${APP_NAMES[$idx]}" bundle="${APP_BUNDLES[$idx]}" b
    b="$(path_bytes "$app")"; trash_path "$app"; record uninstall "$name" "$b"; app_leftovers "$name" "$bundle"
    if [ ${#LEFTOVER_PATHS[@]} -gt 0 ]; then
      header; printf '%b%s leftovers%b\n\n' "$BOLD" "$name" "$RESET"; local j; for ((j=0;j<${#LEFTOVER_LABELS[@]};j++)); do printf '  %s\n' "${LEFTOVER_LABELS[$j]}"; done
      printf '\n'; if confirm "Move these exact app leftovers to Trash?"; then for p in "${LEFTOVER_PATHS[@]}"; do trash_path "$p"; record uninstall-leftover "$p" 0; done; fi
    fi
  done
  header; printf '%bSelected apps were moved to Trash.%b\n\n' "$GREEN" "$RESET"; press_enter
}
