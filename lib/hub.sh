catalog_init(){
  CAT_NAMES=(
    "Zen" "Firefox" "LibreWolf" "Tor Browser"
    "iTerm2" "Mousecape" "Raycast" "Ice" "LuLu" "BetterDisplay" "OnyX"
    "Visual Studio Code" "GitHub CLI" "Python" "Node.js" "Xcode"
  )
  CAT_DESCS=(
    "privacy-focused Firefox-based browser"
    "open-source web browser"
    "hardened privacy-focused Firefox fork"
    "anonymous browsing over the Tor network"
    "advanced terminal emulator"
    "custom cursor manager"
    "launcher and productivity tool"
    "menu bar manager"
    "outbound firewall"
    "display manager"
    "macOS maintenance utility"
    "code editor"
    "GitHub from Terminal"
    "programming language and runtime"
    "JavaScript runtime"
    "Apple app development IDE"
  )
  CAT_PKGS=(
    "zen" "firefox" "librewolf" "tor-browser"
    "iterm2" "" "raycast" "jordanbaird-ice" "lulu" "betterdisplay" "onyx"
    "visual-studio-code" "gh" "python" "node" ""
  )
  CAT_TYPES=(
    cask cask cask cask
    cask url cask cask cask cask cask
    cask formula formula formula url
  )
  CAT_GROUPS=(
    Browsers Browsers Browsers Browsers
    Utilities Utilities Utilities Utilities Utilities Utilities Utilities
    Developer Developer Developer Developer Developer
  )
  CAT_URLS=(
    "https://zen-browser.app/"
    "https://www.mozilla.org/firefox/new/"
    "https://librewolf.net/installation/macos/"
    "https://www.torproject.org/download/"
    "https://iterm2.com/"
    "https://github.com/alexzielenski/Mousecape/releases"
    "https://www.raycast.com/"
    "https://icemenubar.app/"
    "https://objective-see.org/products/lulu.html"
    "https://betterdisplay.pro/"
    "https://www.titanium-software.fr/en/onyx.html"
    "https://code.visualstudio.com/"
    "https://cli.github.com/"
    "https://www.python.org/downloads/macos/"
    "https://nodejs.org/en/download"
    "https://developer.apple.com/xcode/"
  )
}

install_group(){
  local group="$1"
  catalog_init
  local -a labels map
  labels=(); map=()
  local i state pkg typ
  for ((i=0;i<${#CAT_NAMES[@]};i++)); do
    [ "${CAT_GROUPS[$i]}" = "$group" ] || continue
    state=""
    pkg="${CAT_PKGS[$i]}"; typ="${CAT_TYPES[$i]}"
    if have brew && [ "$typ" != url ]; then
      if [ "$typ" = cask ]; then
        brew list --cask "$pkg" >/dev/null 2>&1 && state=" · installed"
      else
        brew list "$pkg" >/dev/null 2>&1 && state=" · installed"
      fi
    fi
    labels+=("${CAT_NAMES[$i]} — ${CAT_DESCS[$i]}$state")
    map+=("$i")
  done

  multi_menu "Install · $group" "${labels[@]}" || return
  [ -n "$MULTI_RESULT" ] || return

  header
  if have brew; then
    printf '%bHomebrew detected.%b Brew-supported selections install through Homebrew; website-only items open their official page.\n\n' "$GREEN" "$RESET"
  else
    printf '%bHomebrew is not installed.%b Zot will open official download pages and will not install a package manager.\n\n' "$YELLOW" "$RESET"
  fi

  local idx real
  for idx in $MULTI_RESULT; do
    real="${map[$idx]}"
    printf '  %-22s %s\n' "${CAT_NAMES[$real]}" "${CAT_DESCS[$real]}"
  done
  printf '\n'
  confirm "Continue with these selections?" || return

  for idx in $MULTI_RESULT; do
    real="${map[$idx]}"
    pkg="${CAT_PKGS[$real]}"
    typ="${CAT_TYPES[$real]}"
    printf '\n%b→ %s%b — %s\n' "$ACCENT" "${CAT_NAMES[$real]}" "$RESET" "${CAT_DESCS[$real]}"

    if [ "$typ" = url ]; then
      open "${CAT_URLS[$real]}" >/dev/null 2>&1 || true
      record open-download "${CAT_NAMES[$real]}" 0
    elif have brew; then
      if [ "$typ" = cask ]; then
        brew install --cask "$pkg" || true
      else
        brew install "$pkg" || true
      fi
      record install "${CAT_NAMES[$real]}" 0
    else
      open "${CAT_URLS[$real]}" >/dev/null 2>&1 || true
      record open-download "${CAT_NAMES[$real]}" 0
    fi
  done

  printf '\n%bInstall action complete.%b\n\n' "$GREEN" "$RESET"
  press_enter
}

install_menu(){
  while :; do
    menu "Install Apps" \
      "Browsers — Zen, Firefox, LibreWolf, Tor" \
      "Utilities — terminal, cursor, menu bar, firewall, display tools" \
      "Developer — editor, CLI, runtimes, Xcode" \
      "Back — return to the hub"
    case "$MENU_RESULT" in
      0) install_group Browsers;;
      1) install_group Utilities;;
      2) install_group Developer;;
      *) return;;
    esac
  done
}

theme_menu(){
  while :; do
    menu "Color Customization" \
      "Cyan — clean default accent" \
      "Purple — violet accent" \
      "Blue — classic blue accent" \
      "Green — terminal green accent" \
      "Amber — warm gold accent" \
      "Red — high-contrast red accent" \
      "Mono — grayscale interface" \
      "Back — keep current theme"
    case "$MENU_RESULT" in
      0) THEME=cyan;;
      1) THEME=purple;;
      2) THEME=blue;;
      3) THEME=green;;
      4) THEME=amber;;
      5) THEME=red;;
      6) THEME=mono;;
      *) return;;
    esac
    save_config
    apply_theme
  done
}

history_screen(){
  header
  printf '%b◆ Recent Zot Operations%b\n\n' "$BOLD$ACCENT" "$RESET"
  if [ -s "$HISTORY_FILE" ]; then
    tail -40 "$HISTORY_FILE" | awk -F'|' '{printf "  %-19s  %-18s  %s\n",$1,$2,$3}'
  else
    echo "  No operations recorded yet."
  fi
  printf '\n'
  press_enter
}

doctor_screen(){
  header
  printf '%b◆ System Doctor%b\n\n' "$BOLD$ACCENT" "$RESET"
  local mac arch free pct swap pressure
  mac="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  arch="$(uname -m)"
  free="$(free_bytes)"
  pct="$(df -k / 2>/dev/null | awk 'NR==2{gsub("%","",$5);print $5+0}')"
  swap="$(sysctl vm.swapusage 2>/dev/null | sed -E 's/.*used = ([0-9.]+[MG]).*/\1/' | head -1)"
  pressure="$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage/{print $5}' | tr -d '%' | head -1)"
  printf '  %-24s %s\n' 'macOS' "$mac"
  printf '  %-24s %s\n' 'Architecture' "$arch"
  printf '  %-24s %s\n' 'Free disk' "$(fmt_bytes "$free")"
  printf '  %-24s %s%% used\n' 'Startup disk' "$pct"
  printf '  %-24s %s\n' 'Swap used' "${swap:-unknown}"
  printf '  %-24s %s\n' 'Memory free' "${pressure:-unknown}%"
  printf '  %-24s %s\n' 'Spotlight' "$(mdutil -s / 2>/dev/null | tail -1 | xargs)"
  printf '  %-24s %s\n' 'Homebrew' "$(have brew && brew --version | head -1 || echo 'not installed')"
  printf '\n%bNotes%b\n' "$BOLD" "$RESET"
  [ "$free" -lt 21474836480 ] && printf '  %b! Less than 20 GB free; low free space can hurt macOS performance.%b\n' "$YELLOW" "$RESET" || printf '  %b✓ Disk free space looks reasonable.%b\n' "$GREEN" "$RESET"
  case "${swap:-0}" in *G) printf '  %b• Swap is in use. Check Performance for sustained high-memory processes.%b\n' "$GRAY" "$RESET";; esac
  printf '\n'
  press_enter
}

status_plain(){
  load_config
  local spotlight services startup optimizations last_opt
  spotlight="$(mdutil -s / 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//' || true)"
  [ -n "$spotlight" ] || spotlight="Unavailable"
  services=0; startup=0
  [ -f "$SERVICE_STATE" ] && services="$(grep -cve '^[[:space:]]*$' "$SERVICE_STATE" 2>/dev/null || echo 0)"
  [ -f "$STARTUP_STATE" ] && startup="$(grep -cve '^[[:space:]]*$' "$STARTUP_STATE" 2>/dev/null || echo 0)"
  last_opt="None recorded"
  if [ -s "$HISTORY_FILE" ]; then
    last_opt="$(grep '|optimize|' "$HISTORY_FILE" 2>/dev/null | tail -1 | awk -F'|' '{print $1 " · " $3}')"
    [ -n "$last_opt" ] || last_opt="None recorded"
  fi

  printf 'Zot %s\n' "$VERSION"
  printf 'Theme: %s\n' "$THEME"
  printf 'Service profile: %s\n' "$PROFILE"
  printf 'Siri: %s\n' "$SIRI"
  printf 'Apple Intelligence: %s\n' "$INTELLIGENCE"
  printf 'Spotlight preference: %s\n' "$SPOTLIGHT"
  printf 'Spotlight actual: %s\n' "$spotlight"
  printf 'Services disabled by Zot: %s\n' "$services"
  printf 'Startup items disabled by Zot: %s\n' "$startup"
  local login_tw="OFF" login_cl="OFF"
  login_tweaks_enabled && login_tw="ON"
  login_clean_enabled && login_cl="ON"
  printf 'Login Tweaks Auto Apply: %s\n' "$login_tw"
  printf 'Login Cleaning Auto Run: %s\n' "$login_cl"
  printf 'Persistent background process: none\n'
  printf 'Last optimization: %s\n' "$last_opt"
}

overview_status(){
  if [ -t 1 ]; then
    printf '%bZot Status%b\n\n' "$BOLD$ACCENT" "$RESET"
    while IFS= read -r line; do
      case "$line" in
        *": off") printf '  %b✓%b %s\n' "$GREEN" "$RESET" "$line";;
        *) printf '  %s\n' "$line";;
      esac
    done < <(status_plain)
  else
    status_plain
  fi
}

overview_status_screen(){
  header
  printf '%b◆ Configuration & Optimization Status%b\n\n' "$BOLD$ACCENT" "$RESET"
  overview_status
  printf '\n'
  press_enter
}

popup_hub(){
  local choice
  while :; do
    choice="$(osascript <<'APPLESCRIPT' 2>/dev/null || true
set choices to {"Health & Performance", "Clean & Storage", "Apps & Updates", "Background & Tweaks", "Maintenance & Tools", "Appearance", "Quit"}
set picked to choose from list choices with title "Zot" with prompt "Choose a section" default items {"Health & Performance"} OK button name "Open" cancel button name "Quit"
if picked is false then return "Quit"
return item 1 of picked
APPLESCRIPT
)"
    case "$choice" in
      "Health"*) health_menu;;
      "Clean"*) storage_menu;;
      "Apps"*) apps_updates_menu;;
      "Background"*) background_menu;;
      "Maintenance"*) maintenance_menu;;
      "Appearance"*) theme_menu;;
      *) return;;
    esac
  done
}

update_zot(){
  header
  printf '%b◆ Updating Zot...%b\n\n' "$BOLD$ACCENT" "$RESET"
  local url="https://api.github.com/repositories/1356850441/contents/install.sh?ref=main"
  if curl -fsSL -H 'Accept: application/vnd.github.raw+json' "$url" | bash; then
    printf '\n%bUpdate complete.%b\n' "$GREEN" "$RESET"
  else
    printf '\n%bUpdate failed.%b\n' "$RED" "$RESET"
  fi
  printf '\n'
  press_enter
}

tools_menu(){
  while :; do
    menu "Tools" \
      "System Check — macOS, disk, RAM, Spotlight" \
      "Recent Actions — Zot operation history" \
      "Update Zot — fetch latest from GitHub" \
      "Activity Monitor — open macOS monitor" \
      "Storage Settings — open macOS settings" \
      "Appearance — choose terminal colors" \
      "Back — previous menu"
    case "$MENU_RESULT" in
      0) doctor_screen;;
      1) history_screen;;
      2) update_zot;;
      3) open -a 'Activity Monitor' >/dev/null 2>&1 || true;;
      4) open 'x-apple.systempreferences:com.apple.settings.Storage' >/dev/null 2>&1 || true;;
      5) theme_menu;;
      *) return;;
    esac
  done
}

health_menu(){
  while :; do
    menu "Health & Performance" \
      "Power & Gaming — select a reversible power mode" \
      "Live Performance — CPU, RAM, swap, active processes" \
      "System Check — disk, memory, Apple security" \
      "Zot Status — saved tweaks and login automation" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) mode_menu;;
      1) status_screen;;
      2) doctor_screen;;
      3) overview_status_screen;;
      *) return;;
    esac
  done
}

storage_menu(){
  while :; do
    menu "Clean & Storage" \
      "Clean — reviewed caches, logs and junk files" \
      "Scan — see recoverable storage without deletion" \
      "Find Large Files — installers, backups and projects" \
      "Uninstall Apps — review apps and leftovers" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) clean_menu;;
      1) scan_screen;;
      2) analyze_menu;;
      3) apps_screen;;
      *) return;;
    esac
  done
}

apps_updates_menu(){
  while :; do
    menu "Apps & Updates" \
      "Install Apps — curated optional applications" \
      "Update Zot — download the newest tool version" \
      "macOS Updates — open System Settings" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) install_menu;;
      1) update_zot;;
      2) open 'x-apple.systempreferences:com.apple.Software-Update-Settings.extension' >/dev/null 2>&1 || open -a 'System Settings';;
      *) return;;
    esac
  done
}

background_menu(){
  while :; do
    menu "Background & Tweaks" \
      "Service Controls — Siri, AI, Spotlight and presets" \
      "Service Status — verify launchd overrides" \
      "Login Automation — reapply tweaks after restart" \
      "Startup Apps — inspect and manage third-party jobs" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) services_screen;;
      1) services_audit_screen;;
      2) login_hub;;
      3) startup_screen;;
      *) return;;
    esac
  done
}

maintenance_menu(){
  while :; do
    menu "Maintenance & Tools" \
      "System Maintenance — DNS, Quick Look, disk checks" \
      "Tools — diagnostics, history, update and settings" \
      "Standalone Cleaner — separate local cleanup command" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) optimize_screen;;
      1) tools_menu;;
      2) header; printf 'Your local cleanup command is independent of Zot.\nRun cleanup from Terminal if you installed it separately.\n\n'; press_enter;;
      *) return;;
    esac
  done
}

hub(){
  while :; do
    basic_snapshot
    MENU_SUBTITLE="$SNAP_MODEL · $SNAP_FREE free · RAM $SNAP_MEM"
    menu "Main Menu" \
      "Health & Performance — live usage and power modes" \
      "Clean & Storage — clear junk and manage space" \
      "Apps & Updates — install tools and update Zot" \
      "Background & Tweaks — services and login jobs" \
      "Maintenance & Tools — system refresh and diagnostics" \
      "Appearance — terminal colors" \
      "Quit — close Zot"
    MENU_SUBTITLE=""
    case "$MENU_RESULT" in
      0) health_menu;;
      1) storage_menu;;
      2) apps_updates_menu;;
      3) background_menu;;
      4) maintenance_menu;;
      5) theme_menu;;
      *) clear; return;;
    esac
  done
}

usage(){
  cat <<EOF
Zot $VERSION — macOS utility

Start here:
  zot                       Open the simplified menu
  zot mode                  Choose Gaming / Battery Saver / Restore
  zot mode status           Read-only power settings
  zot mode health           CPU, RAM, swap, power and throttling hints
  zot mode game             Keep Low Power Mode OFF (review & confirm)
  zot mode battery          Low Power Mode ON on battery (confirm)
  zot mode restore          Restore saved original power settings

Maintenance:
  zot status                Zot settings and login jobs
  zot performance           Live CPU / RAM dashboard
  zot doctor                Read-only system health
  zot audit                 Read-only service/persistence audit
  zot clean                 Reviewed cache cleanup (Zot)
  zot scan                  Read-only storage estimate
  zot analyze               Large files and disk analyzer
  zot optimize              Selected maintenance tasks
  zot apps                  Uninstall and review leftovers
  zot install               Curated app installer
  zot update                Update Zot

Advanced:
  zot services              Service & privacy controls
  zot services audit        Read-only service audit
  zot login                 Configure login reapply jobs
  zot startup               Startup/background services
  zot restore               Restore Zot-managed service/startup changes
  zot history               Operations history
  zot theme                 Appearance
  zot gui                   Native macOS popup launcher
  zot help                  Show this help

Quick aliases: zot-status, zot-login, zot-mode, zot-audit, zot-clean.
Other existing zot-* aliases remain available. The separate local
"cleanup" command is NOT installed or managed by Zot.
EOF
}

restore_all(){
  header
  confirm "Restore all startup and service changes recorded by Zot?" || return 0
  if login_tweaks_enabled || login_system_enabled; then
    printf '\n%bDisabling Tweaks Auto Apply first so restored changes stay restored.%b\n' "$YELLOW" "$RESET"
    login_tweaks_disable
  fi
  services_restore
  if [ -s "$STARTUP_STATE" ]; then
    while IFS='|' read -r kind label path; do
      [ -n "$label" ] || continue
      if [ "$kind" = user ]; then
        launchctl enable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true
        [ -f "$path" ] && launchctl bootstrap "gui/$UID_NUM" "$path" >/dev/null 2>&1 || true
      else
        sudo launchctl enable "system/$label" >/dev/null 2>&1 || true
        [ -f "$path" ] && sudo launchctl bootstrap system "$path" >/dev/null 2>&1 || true
      fi
    done < "$STARTUP_STATE"
    : > "$STARTUP_STATE"
  fi
  printf '\n%bRestore complete. Restart macOS if a restored service does not return immediately.%b\n\n' "$GREEN" "$RESET"
}

main(){
  load_config
  local invoked cmd
  invoked="$(basename "$0")"
  if [[ "$invoked" == zot-* ]]; then
    cmd="${invoked#zot-}"
  else
    cmd="${1:-}"
    [ "$#" -gt 0 ] && shift
  fi

  case "$cmd" in
    '') if [ -t 0 ] && [ -t 1 ]; then hub; else usage; fi;;
    mode|power|gaming) mode_command "${1:-}";;
    status) overview_status;;
    performance) status_screen;;
    audit) services_audit;;
    scan) scan_screen;;
    clean) clean_menu;;
    analyze) analyze_menu;;
    apps) apps_screen;;
    startup) startup_screen;;
    login) login_hub;;
    optimize) optimize_screen;;
    install) install_menu;;
    services) if [ "${1:-}" = audit ] || [ "${1:-}" = status ]; then services_audit; else services_screen; fi;;
    theme|appearance) theme_menu;;
    gui|popup) popup_hub;;
    doctor) doctor_screen;;
    history) history_screen;;
    restore) restore_all;;
    update) update_zot;;
    login-run-tweaks) login_apply_tweaks user;;
    login-run-cleaning) login_clean_run;;
    login-disable-all) login_disable_all;;
    reapply-user) services_apply >/dev/null 2>&1 || true;;
    version|--version|-v) echo "$VERSION";;
    help|--help|-h) usage;;
    *) usage; return 2;;
  esac
}
