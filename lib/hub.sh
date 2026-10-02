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
set choices to {"Status — configuration overview", "Performance — live CPU/RAM", "Scan — read-only storage scan", "Clean — cleanup hub", "Analyze — storage explorer", "Apps — uninstall and leftovers", "Startup — background/login items", "Login — Zot auto-run items", "Optimize — maintenance tasks", "Install — curated apps", "Services — macOS feature controls", "Theme — terminal colors", "Quit"}
set picked to choose from list choices with title "Zot" with prompt "macOS Utility Hub" default items {"Status — configuration overview"} OK button name "Open" cancel button name "Quit"
if picked is false then return "Quit"
return item 1 of picked
APPLESCRIPT
)"
    case "$choice" in
      "Status"*) 
        local summary
        summary="$(status_plain)"
        osascript - "$summary" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
  display dialog item 1 of argv with title "Zot Status" buttons {"Done"} default button "Done"
end run
APPLESCRIPT
        ;;
      "Performance"*) status_screen;;
      "Scan"*) scan_screen;;
      "Clean"*) clean_menu;;
      "Analyze"*) analyze_menu;;
      "Apps"*) apps_screen;;
      "Startup"*) startup_screen;;
      "Login"*) login_hub;;
      "Optimize"*) optimize_screen;;
      "Install"*) install_menu;;
      "Services"*) services_screen;;
      "Theme"*) theme_menu;;
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
      "System Doctor — quick health checks" \
      "Operation History — recent Zot changes" \
      "Color Customization — choose terminal theme" \
      "Native Popup Hub — built-in macOS dialog launcher" \
      "Update Zot — install latest version" \
      "Activity Monitor — open Apple's process monitor" \
      "Storage Settings — open macOS storage settings" \
      "Back — return to the hub"
    case "$MENU_RESULT" in
      0) doctor_screen;;
      1) history_screen;;
      2) theme_menu;;
      3) popup_hub;;
      4) update_zot;;
      5) open -a 'Activity Monitor' >/dev/null 2>&1 || true;;
      6) open 'x-apple.systempreferences:com.apple.settings.Storage' >/dev/null 2>&1 || true;;
      *) return;;
    esac
  done
}

hub(){
  while :; do
    basic_snapshot
    MENU_SUBTITLE="$SNAP_MODEL · $SNAP_FREE free · RAM $SNAP_MEM"
    menu "Hub" \
      "Status — macOS features, Zot profile, optimization state" \
      "Performance — live CPU, RAM, swap, and top processes" \
      "Scan — read-only cleanup and storage estimate" \
      "Clean — caches, browsers, developer files, projects" \
      "Analyze Storage — large files, installers, backups" \
      "Apps & Leftovers — uninstall apps and related files" \
      "Startup & Background — manage existing login/background jobs" \
      "Login Items — auto-reapply tweaks or auto-clean at login" \
      "Optimize — safe macOS maintenance tasks" \
      "Install Apps — curated browsers, utilities, developer tools" \
      "Services & Features — profile, Siri, AI, Spotlight" \
      "Appearance — customize Zot terminal colors" \
      "Tools — doctor, history, popup hub, update" \
      "Quit — close Zot"
    MENU_SUBTITLE=""
    case "$MENU_RESULT" in
      0) overview_status_screen;;
      1) status_screen;;
      2) scan_screen;;
      3) clean_menu;;
      4) analyze_menu;;
      5) apps_screen;;
      6) startup_screen;;
      7) login_hub;;
      8) optimize_screen;;
      9) install_menu;;
      10) services_screen;;
      11) theme_menu;;
      12) tools_menu;;
      *) clear; return;;
    esac
  done
}

usage(){
  cat <<EOF
Zot $VERSION

Commands:
  zot                         interactive terminal hub
  zot status                  current Zot/macOS configuration overview
  zot performance             live CPU, RAM, swap, and process dashboard
  zot scan                    read-only cleanup/storage scan
  zot clean                   cache and rebuildable-file cleanup hub
  zot analyze                 large-file, installer, and backup analyzer
  zot apps                    app uninstaller and leftover reviewer
  zot startup                 inspect existing login/background items
  zot login                   configure Zot tweaks/cleaning at login
  zot optimize                safe maintenance and optimization tasks
  zot install                 curated app installer
  zot services                macOS service/profile controls
  zot theme                   terminal color customization
  zot gui                     native macOS popup launcher
  zot doctor                  quick system health checks
  zot history                 recent Zot operations
  zot restore                 restore Zot-managed service/startup changes
  zot update                  update Zot
  zot version                 print Zot version

Hyphen shortcuts:
  zot-status                  configuration overview
  zot-performance             live performance dashboard
  zot-scan                    read-only scan
  zot-clean                   cleanup hub
  zot-analyze                 storage analyzer
  zot-apps                    app uninstaller
  zot-startup                 startup manager
  zot-login                   Zot login-items hub
  zot-optimize                optimization hub
  zot-install                 app installer
  zot-services                service controls
  zot-theme                   color customization
  zot-gui                     native popup launcher
  zot-doctor                  system doctor
  zot-history                 operation history
  zot-restore                 restore Zot-managed changes
  zot-update                  update Zot
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
  fi

  case "$cmd" in
    '') if [ -t 0 ] && [ -t 1 ]; then hub; else usage; fi;;
    status) overview_status;;
    performance) status_screen;;
    scan) scan_screen;;
    clean) clean_menu;;
    analyze) analyze_menu;;
    apps) apps_screen;;
    startup) startup_screen;;
    login) login_hub;;
    optimize) optimize_screen;;
    install) install_menu;;
    services) services_screen;;
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
