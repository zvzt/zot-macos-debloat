scan_recoverable(){
  local total=0 p
  for p in "$HOME/Library/Caches" "$HOME/Library/Logs" "$HOME/.Trash" "$HOME/Library/Developer/Xcode/DerivedData"; do
    [ -e "$p" ] && total=$((total + $(path_bytes "$p")))
  done
  for p in     "$HOME/Library/Caches/com.apple.Safari"     "$HOME/Library/Caches/Google/Chrome"     "$HOME/Library/Caches/Firefox"     "$HOME/Library/Caches/BraveSoftware/Brave-Browser"     "$HOME/Library/Caches/Microsoft Edge"     "$HOME/Library/Caches/company.thebrowser.Browser"; do
    [ -e "$p" ] && total=$((total + $(path_bytes "$p")))
  done
  echo "$total"
}
scan_screen(){
  header
  printf '%bScanning common cleanup locations...%b\n\n' "$BOLD" "$RESET"
  local -a labels paths
  labels=("User app caches" "User logs" "Trash" "Xcode DerivedData" "Homebrew cache" "Mobile device backups")
  paths=("$HOME/Library/Caches" "$HOME/Library/Logs" "$HOME/.Trash" "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/Library/Caches/Homebrew" "$HOME/Library/Application Support/MobileSync/Backup")
  local i total=0 b
  for ((i=0;i<${#labels[@]};i++)); do b="$(path_bytes "${paths[$i]}")"; total=$((total+b)); printf '  %-28s %10s\n' "${labels[$i]}" "$(fmt_bytes "$b")"; done
  printf '\n  %-28s %10s\n' 'Quick-scan total' "$(fmt_bytes "$total")"
  printf '\n%bThis is a read-only estimate. Clean/Analyze screens review exact items before changes.%b\n\n' "$GRAY" "$RESET"; press_enter
}
browser_targets(){
  BROWSER_NAMES=("Safari" "Google Chrome" "Firefox" "Brave" "Microsoft Edge" "Arc")
  BROWSER_PATHS=("$HOME/Library/Caches/com.apple.Safari" "$HOME/Library/Caches/Google/Chrome" "$HOME/Library/Caches/Firefox" "$HOME/Library/Caches/BraveSoftware/Brave-Browser" "$HOME/Library/Caches/Microsoft Edge" "$HOME/Library/Caches/company.thebrowser.Browser")
  BROWSER_PROCS=("Safari" "Google Chrome" "firefox" "Brave Browser" "Microsoft Edge" "Arc")
}
clean_basic(){
  local mode="$1"; local -a names paths choices
  names=("User app caches" "User logs" "Trash" "Xcode DerivedData")
  paths=("$HOME/Library/Caches" "$HOME/Library/Logs" "$HOME/.Trash" "$HOME/Library/Developer/Xcode/DerivedData")
  local i b; choices=()
  for ((i=0;i<${#names[@]};i++)); do b="$(path_bytes "${paths[$i]}")"; choices+=("${names[$i]}  ·  $(fmt_bytes "$b")"); done
  if [ "$mode" = "quick" ]; then MULTI_RESULT="0 1 2"; else multi_menu "Clean · General" "${choices[@]}" || return; fi
  [ -n "$MULTI_RESULT" ] || return
  header; printf '%bSelected cleanup%b\n\n' "$BOLD" "$RESET"
  local total=0 idx
  for idx in $MULTI_RESULT; do b="$(path_bytes "${paths[$idx]}")"; total=$((total+b)); printf '  %-28s %10s\n' "${names[$idx]}" "$(fmt_bytes "$b")"; done
  printf '\nPotential cleanup: %b%s%b\n\n' "$CYAN" "$(fmt_bytes "$total")" "$RESET"
  confirm "Permanently remove these rebuildable files/caches?" || return
  local before after; before="$(free_bytes)"
  for idx in $MULTI_RESULT; do b="$(path_bytes "${paths[$idx]}")"; printf 'Cleaning %s...\n' "${names[$idx]}"; clear_dir "${paths[$idx]}"; record clean "${names[$idx]}" "$b"; done
  after="$(free_bytes)"; printf '\n%bDone. Disk space gained: %s%b\n\n' "$GREEN" "$(fmt_bytes $((after-before)))" "$RESET"; press_enter
}
clean_browsers(){
  browser_targets; local -a options=(); local i b
  for ((i=0;i<${#BROWSER_NAMES[@]};i++)); do [ -e "${BROWSER_PATHS[$i]}" ] || continue; b="$(path_bytes "${BROWSER_PATHS[$i]}")"; options+=("${BROWSER_NAMES[$i]} cache  ·  $(fmt_bytes "$b")|$i"); done
  [ ${#options[@]} -gt 0 ] || { header; echo "No supported browser caches found."; press_enter; return; }
  local -a labels=(); for i in "${options[@]}"; do labels+=("${i%%|*}"); done
  multi_menu "Clean · Browsers" "${labels[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header; printf '%bBrowser cleanup%b\n\n' "$BOLD" "$RESET"; local idx real proc
  for idx in $MULTI_RESULT; do real="${options[$idx]##*|}"; proc="${BROWSER_PROCS[$real]}"; if pgrep -x "$proc" >/dev/null 2>&1 || pgrep -f "/$proc" >/dev/null 2>&1; then printf '  %b%s is running and will be skipped.%b\n' "$YELLOW" "${BROWSER_NAMES[$real]}" "$RESET"; fi; done
  printf '\n'; confirm "Clean selected browser disk caches?" || return
  for idx in $MULTI_RESULT; do real="${options[$idx]##*|}"; proc="${BROWSER_PROCS[$real]}"; if pgrep -x "$proc" >/dev/null 2>&1 || pgrep -f "/$proc" >/dev/null 2>&1; then continue; fi; b="$(path_bytes "${BROWSER_PATHS[$real]}")"; clear_dir "${BROWSER_PATHS[$real]}"; record clean "${BROWSER_NAMES[$real]} cache" "$b"; done
  printf '\n%bBrowser caches cleaned.%b\n\n' "$GREEN" "$RESET"; press_enter
}
clean_dev(){
  local -a labels keys; labels=(); keys=()
  if [ -d "$HOME/Library/Developer/Xcode/DerivedData" ]; then labels+=("Xcode DerivedData · $(fmt_bytes "$(path_bytes "$HOME/Library/Developer/Xcode/DerivedData")")"); keys+=("xcode"); fi
  if have brew; then labels+=("Homebrew old versions + downloads"); keys+=("brew"); fi
  if have python3 && python3 -m pip --version >/dev/null 2>&1; then labels+=("Python pip cache"); keys+=("pip"); fi
  if have npm; then labels+=("npm cache"); keys+=("npm"); fi
  if have pnpm; then labels+=("pnpm unused store packages"); keys+=("pnpm"); fi
  if have yarn; then labels+=("Yarn cache"); keys+=("yarn"); fi
  if have xcrun; then labels+=("Unavailable Xcode simulators"); keys+=("sim"); fi
  [ ${#labels[@]} -gt 0 ] || { header; echo "No supported developer cleanup targets found."; press_enter; return; }
  multi_menu "Clean · Developer" "${labels[@]}" || return; [ -n "$MULTI_RESULT" ] || return; confirm "Run selected developer cleanup tasks?" || return
  local idx key
  for idx in $MULTI_RESULT; do key="${keys[$idx]}"; printf 'Running %s...\n' "${labels[$idx]}"; case "$key" in xcode) clear_dir "$HOME/Library/Developer/Xcode/DerivedData";; brew) brew cleanup -s || true;; pip) python3 -m pip cache purge || true;; npm) npm cache clean --force || true;; pnpm) pnpm store prune || true;; yarn) yarn cache clean || true;; sim) xcrun simctl delete unavailable || true;; esac; record clean "developer:$key" 0; done
  printf '\n%bDeveloper cleanup complete.%b\n\n' "$GREEN" "$RESET"; press_enter
}
find_project_artifacts(){
  ART_PATHS=(); ART_LABELS=(); local root item parent age size now mtime; now="$(date +%s)"
  for root in "$HOME/Projects" "$HOME/GitHub" "$HOME/dev" "$HOME/Developer" "$HOME/Documents/Projects"; do
    [ -d "$root" ] || continue
    while IFS= read -r item; do
      [ -n "$item" ] || continue; [ -L "$item" ] && continue; parent="$(dirname "$item")"
      [ -d "$parent/.git" ] || [ -d "$(dirname "$parent")/.git" ] || continue
      mtime="$(stat -f %m "$item" 2>/dev/null || echo "$now")"; age=$(( (now-mtime)/86400 )); [ "$age" -ge 7 ] || continue
      size="$(path_bytes "$item")"; ART_PATHS+=("$item"); ART_LABELS+=("$(basename "$item") · $(fmt_bytes "$size") · ${age}d · ${parent#$HOME/}"); [ ${#ART_PATHS[@]} -ge 80 ] && break 2
    done < <(find "$root" -maxdepth 5 -type d \( -name node_modules -o -name target -o -name .build -o -name dist \) -prune 2>/dev/null)
  done
}
purge_projects(){
  header; printf '%bScanning common project folders...%b\n' "$BOLD" "$RESET"; find_project_artifacts
  [ ${#ART_PATHS[@]} -gt 0 ] || { echo; echo "No inactive rebuildable project artifacts found (7d+)."; press_enter; return; }
  multi_menu "Projects · rebuildable artifacts (7d+)" "${ART_LABELS[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header; printf '%bThese are permanently deleted because they are rebuildable artifacts.%b\n\n' "$YELLOW" "$RESET"; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${ART_PATHS[$idx]#$HOME/}"; done
  printf '\n'; confirm "Delete selected project artifacts?" || return
  local b; for idx in $MULTI_RESULT; do b="$(path_bytes "${ART_PATHS[$idx]}")"; rm -rf "${ART_PATHS[$idx]}"; record purge "${ART_PATHS[$idx]}" "$b"; done
  printf '\n%bProject artifacts removed.%b\n\n' "$GREEN" "$RESET"; press_enter
}
clean_aged_caches(){
  menu "Age-based Cache Clean" "Older than 7 days" "Older than 30 days" "Older than 90 days" "Back"; local days
  case "$MENU_RESULT" in 0) days=7;; 1) days=30;; 2) days=90;; *) return;; esac
  header; printf '%bThis removes only cache files older than %s days, then prunes empty cache folders.%b\n\n' "$BOLD" "$days" "$RESET"; confirm "Continue?" || return
  local before after; before="$(free_bytes)"; find "$HOME/Library/Caches" -type f -mtime +"$days" -delete 2>/dev/null || true; find "$HOME/Library/Caches" -type d -empty -delete 2>/dev/null || true; after="$(free_bytes)"
  record clean "aged-cache:${days}d" "$((after-before))"; printf '\n%bRecovered approximately %s.%b\n\n' "$GREEN" "$(fmt_bytes $((after-before)))" "$RESET"; press_enter
}
deep_clean_wizard(){ local before after; before="$(free_bytes)"; clean_basic custom; clean_browsers; clean_dev; after="$(free_bytes)"; header; printf '%bDeep Clean wizard finished.%b\n\n' "$GREEN" "$RESET"; printf 'Net free-space change: %s\n\n' "$(fmt_bytes $((after-before)))"; press_enter; }
clean_menu(){ while :; do menu "Clean" "Quick Clean" "Deep Clean Wizard" "General Caches / Logs / Trash" "Age-based Cache Clean" "Browser Caches" "Developer Caches" "Project Artifacts" "Back"; case "$MENU_RESULT" in 0) clean_basic quick;; 1) deep_clean_wizard;; 2) clean_basic custom;; 3) clean_aged_caches;; 4) clean_browsers;; 5) clean_dev;; 6) purge_projects;; *) return;; esac; done; }
