plist_label(){ /usr/libexec/PlistBuddy -c 'Print :Label' "$1" 2>/dev/null || basename "$1" .plist; }
list_startup(){
  START_PATHS=(); START_LABELS=(); START_KINDS=(); START_NAMES=()
  local p label
  for p in "$HOME/Library/LaunchAgents"/*.plist; do [ -f "$p" ] || continue; label="$(plist_label "$p")"; START_PATHS+=("$p"); START_NAMES+=("$label"); START_KINDS+=("user"); START_LABELS+=("User · $label"); done
  for p in /Library/LaunchAgents/*.plist /Library/LaunchDaemons/*.plist; do [ -f "$p" ] || continue; label="$(plist_label "$p")"; START_PATHS+=("$p"); START_NAMES+=("$label"); START_KINDS+=("system"); START_LABELS+=("System · $label"); done
}
startup_disable(){
  local kind="$1" label="$2" path="$3"; mkdir -p "$STATE_DIR"
  if [ "$kind" = user ]; then launchctl disable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true; launchctl bootout "gui/$UID_NUM" "$path" >/dev/null 2>&1 || true
  else sudo launchctl disable "system/$label" >/dev/null 2>&1 || true; sudo launchctl bootout system "$path" >/dev/null 2>&1 || true; fi
  grep -Fqx "$kind|$label|$path" "$STARTUP_STATE" 2>/dev/null || printf '%s|%s|%s\n' "$kind" "$label" "$path" >> "$STARTUP_STATE"; record startup-disable "$label" 0
}
startup_restore_all(){
  [ -s "$STARTUP_STATE" ] || { header; echo "No startup items disabled by Zot are recorded."; press_enter; return; }
  header; printf '%bRestoring startup items disabled by Zot...%b\n\n' "$BOLD" "$RESET"
  while IFS='|' read -r kind label path; do
    [ -n "$label" ] || continue
    if [ "$kind" = user ]; then launchctl enable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true; [ -f "$path" ] && launchctl bootstrap "gui/$UID_NUM" "$path" >/dev/null 2>&1 || true
    else sudo launchctl enable "system/$label" >/dev/null 2>&1 || true; [ -f "$path" ] && sudo launchctl bootstrap system "$path" >/dev/null 2>&1 || true; fi
    record startup-restore "$label" 0
  done < "$STARTUP_STATE"
  : > "$STARTUP_STATE"; printf '%bStartup items restored.%b\n\n' "$GREEN" "$RESET"; press_enter
}
startup_screen(){
  while :; do
    menu "Startup & Background" "Review LaunchAgents / LaunchDaemons" "Restore Items Disabled by Zot" "Show macOS Background Item Report" "Back"
    case "$MENU_RESULT" in
      0)
        header; printf '%bScanning startup items...%b\n' "$BOLD" "$RESET"; list_startup
        [ ${#START_PATHS[@]} -gt 0 ] || { echo "No startup plists found."; press_enter; continue; }
        multi_menu "Startup · system items are advanced" "${START_LABELS[@]}" || continue; [ -n "$MULTI_RESULT" ] || continue
        header; printf '%bReview selected startup items%b\n\n' "$BOLD" "$RESET"; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${START_LABELS[$idx]}"; done
        printf '\n%bDisabling a third-party helper can stop auto-start/update/background features.%b\n\n' "$YELLOW" "$RESET"; confirm "Disable selected startup items?" || continue
        for idx in $MULTI_RESULT; do startup_disable "${START_KINDS[$idx]}" "${START_NAMES[$idx]}" "${START_PATHS[$idx]}"; done
        printf '\n%bDisabled and recorded for restore.%b\n' "$GREEN" "$RESET"; press_enter;;
      1) startup_restore_all;;
      2) header; printf '%bmacOS Background Task Management report%b\n\n' "$BOLD" "$RESET"; if have sfltool; then sfltool dumpbtm 2>/dev/null | head -120; else echo "sfltool is unavailable on this macOS version."; fi; printf '\n'; press_enter;;
      *) return;;
    esac
  done
}
optimize_screen(){
  local -a labels keys
  labels=("Flush DNS cache" "Reset Quick Look thumbnail cache" "Rebuild LaunchServices app registration" "Verify startup volume (read-only)" "Reindex Spotlight" "Run macOS periodic maintenance")
  keys=(dns ql ls disk spotlight periodic)
  have brew && { labels+=("Homebrew cleanup"); keys+=(brew); }; have xcrun && { labels+=("Delete unavailable simulators"); keys+=(sim); }
  multi_menu "Optimize · safe maintenance tasks" "${labels[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header; printf '%bOptimization plan%b\n\n' "$BOLD" "$RESET"; local idx; for idx in $MULTI_RESULT; do printf '  %s\n' "${labels[$idx]}"; done
  printf '\n%bNo RAM purge, forced process killing, defrag, or random system-cache deletion is used.%b\n\n' "$GRAY" "$RESET"; confirm "Run selected maintenance tasks?" || return
  local key lsreg
  for idx in $MULTI_RESULT; do
    key="${keys[$idx]}"; printf '\n%b→ %s%b\n' "$CYAN" "${labels[$idx]}" "$RESET"
    case "$key" in
      dns) sudo dscacheutil -flushcache 2>/dev/null || dscacheutil -flushcache 2>/dev/null || true; sudo killall -HUP mDNSResponder 2>/dev/null || true;;
      ql) qlmanage -r cache 2>/dev/null || true;;
      ls) lsreg="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"; [ -x "$lsreg" ] && "$lsreg" -kill -r -domain local -domain system -domain user >/dev/null 2>&1 || true;;
      disk) diskutil verifyVolume / || true;;
      spotlight) sudo mdutil -E / || true;;
      periodic) sudo periodic daily weekly monthly || true;;
      brew) brew cleanup -s || true;;
      sim) xcrun simctl delete unavailable || true;;
    esac
    record optimize "$key" 0
  done
  printf '\n%bOptimization pass complete.%b\n\n' "$GREEN" "$RESET"; press_enter
}
preset_file(){ case "$1" in balanced) echo "$PRESETS_DIR/balanced.txt";; aggressive) echo "$PRESETS_DIR/aggressive.txt";; siri) echo "$PRESETS_DIR/siri.txt";; intelligence) echo "$PRESETS_DIR/apple-intelligence.txt";; esac; }
read_preset(){ [ -f "$1" ] || return 0; sed 's/#.*//;/^[[:space:]]*$/d' "$1"; }
registered(){ launchctl print "$1/$2" >/dev/null 2>&1; }
plist_kind(){
  local l="$1"
  [ -e "/System/Library/LaunchAgents/$l.plist" ] || [ -e "/Library/LaunchAgents/$l.plist" ] || [ -e "/Library/Apple/System/Library/LaunchAgents/$l.plist" ] || [ -e "/System/Cryptexes/App/System/Library/LaunchAgents/$l.plist" ] && echo user
  [ -e "/System/Library/LaunchDaemons/$l.plist" ] || [ -e "/Library/LaunchDaemons/$l.plist" ] || [ -e "/Library/Apple/System/Library/LaunchDaemons/$l.plist" ] || [ -e "/System/Cryptexes/App/System/Library/LaunchDaemons/$l.plist" ] && echo system
}
actual_disabled(){ local out; out="$(launchctl print-disabled "$1" 2>/dev/null || true)"; printf '%s\n' "$out" | grep -F "\"$2\" => true" >/dev/null 2>&1 || printf '%s\n' "$out" | grep -F "\"$2\" => disabled" >/dev/null 2>&1; }
service_desired(){ read_preset "$(preset_file balanced)"; [ "$PROFILE" = aggressive ] && read_preset "$(preset_file aggressive)"; [ "$SIRI" = disable ] && read_preset "$(preset_file siri)"; [ "$INTELLIGENCE" = disable ] && read_preset "$(preset_file intelligence)"; }
service_disable(){
  local kind="$1" label="$2" domain entry; if [ "$kind" = user ]; then domain="gui/$UID_NUM"; else domain=system; fi; entry="$kind|$label"; actual_disabled "$domain" "$label" && return 0
  if [ "$kind" = user ]; then launchctl disable "$domain/$label" >/dev/null 2>&1 || return 1; launchctl bootout "$domain/$label" >/dev/null 2>&1 || true
  else sudo launchctl disable "system/$label" >/dev/null 2>&1 || return 1; sudo launchctl bootout "system/$label" >/dev/null 2>&1 || true; fi
  grep -Fqx "$entry" "$SERVICE_STATE" 2>/dev/null || printf '%s\n' "$entry" >> "$SERVICE_STATE"
}
services_apply(){
  load_config; mkdir -p "$STATE_DIR"; touch "$SERVICE_STATE"; services_restore >/dev/null 2>&1 || true
  local labels label kind changed=0; labels="$(service_desired | awk '!seen[$0]++')"
  while IFS= read -r label; do
    [ -n "$label" ] || continue; kind=""; registered "gui/$UID_NUM" "$label" && kind=user; registered system "$label" && kind=system; [ -n "$kind" ] || kind="$(plist_kind "$label" | head -1)"; [ -n "$kind" ] || continue
    service_disable "$kind" "$label" && changed=$((changed+1))
  done <<< "$labels"
  if [ "$SPOTLIGHT" = off ]; then if mdutil -s / 2>/dev/null | grep -qi 'Indexing enabled'; then sudo mdutil -i off / >/dev/null 2>&1 && echo changed > "$SPOTLIGHT_STATE"; fi
  elif [ -f "$SPOTLIGHT_STATE" ]; then sudo mdutil -i on / >/dev/null 2>&1 || true; rm -f "$SPOTLIGHT_STATE"; fi
  record services-apply "$PROFILE" 0; printf '%bApplied service profile. %s targets processed.%b\n' "$GREEN" "$changed" "$RESET"
}
services_restore(){
  [ -f "$SERVICE_STATE" ] || return 0
  while IFS='|' read -r kind label; do [ -n "$label" ] || continue; if [ "$kind" = user ]; then launchctl enable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true; else sudo launchctl enable "system/$label" >/dev/null 2>&1 || true; fi; done < "$SERVICE_STATE"
  : > "$SERVICE_STATE"; if [ -f "$SPOTLIGHT_STATE" ]; then sudo mdutil -i on / >/dev/null 2>&1 || true; rm -f "$SPOTLIGHT_STATE"; fi; record services-restore all 0
}
services_screen(){
  load_config
  while :; do
    menu "Services & Features" "Profile: $PROFILE" "Siri: $SIRI" "Apple Intelligence: $INTELLIGENCE" "Spotlight indexing: $SPOTLIGHT" "Apply Selected Configuration" "Restore Zot Service Changes" "Back"
    case "$MENU_RESULT" in
      0) [ "$PROFILE" = balanced ] && PROFILE=aggressive || PROFILE=balanced; save_config;;
      1) [ "$SIRI" = keep ] && SIRI=disable || SIRI=keep; save_config;;
      2) [ "$INTELLIGENCE" = keep ] && INTELLIGENCE=disable || INTELLIGENCE=keep; save_config;;
      3) [ "$SPOTLIGHT" = keep ] && SPOTLIGHT=off || SPOTLIGHT=keep; save_config;;
      4) header; printf '%bBalanced/aggressive service changes can affect optional macOS features.%b\n\n' "$YELLOW" "$RESET"; confirm "Apply this configuration?" && services_apply; printf '\n'; press_enter;;
      5) header; confirm "Restore service changes recorded by Zot?" && services_restore; printf '\n%bRestore complete.%b\n' "$GREEN" "$RESET"; press_enter;;
      *) return;;
    esac
  done
}
