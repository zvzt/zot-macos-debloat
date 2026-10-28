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
  CAT_APP_NAMES=(
    "Zen" "Firefox" "LibreWolf" "Tor Browser"
    "iTerm" "Mousecape" "Raycast" "Ice" "LuLu" "BetterDisplay" "OnyX"
    "Visual Studio Code" "" "" "" "Xcode"
  )
}

zot_brew_path(){
  if have brew; then command -v brew
  elif [ -x /opt/homebrew/bin/brew ]; then printf '%s\n' /opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then printf '%s\n' /usr/local/bin/brew
  else return 1
  fi
}

# Use only Homebrew's official installer, after explicit user approval.
# Helper functions can be replaced by mocks in the offline installer tests.
zot_homebrew_can_prompt(){ [ -t 0 ] && [ -t 1 ]; }

zot_homebrew_download(){
  curl --fail --location --silent --show-error --connect-timeout 15 --max-time 120 \
    --output "$1" "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
}

zot_homebrew_run(){ /bin/bash "$1"; }

zot_install_homebrew(){
  local brew_bin tmp rc=0
  brew_bin="$(zot_brew_path 2>/dev/null || true)"
  if [ -n "$brew_bin" ]; then
    printf 'Homebrew is already installed: %s\n' "$brew_bin"
    return 0
  fi
  if [ "$(uname -s)" != Darwin ]; then
    printf '%bHomebrew setup here supports macOS only.%b\n' "$RED" "$RESET"
    return 1
  fi
  if ! zot_homebrew_can_prompt; then
    printf '%bRun Zot in an interactive Terminal to install Homebrew.%b\n' "$YELLOW" "$RESET"
    return 1
  fi
  if ! have curl; then
    printf '%bcurl is unavailable; Homebrew installation cannot start.%b\n' "$RED" "$RESET"
    return 1
  fi

  printf '\n%bHomebrew is not installed.%b\n' "$YELLOW" "$RESET"
  printf 'Zot can download and run the official Homebrew installation script.\n'
  printf 'Source: https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh\n'
  printf 'Homebrew may request your administrator password and install Apple Command Line Tools.\n'
  printf 'Its installer will also explain its changes and request approval.\n\n'
  confirm "Install Homebrew now?" || return 1

  tmp="$(mktemp "${TMPDIR:-/tmp}/zot-homebrew.XXXXXX")" || {
    printf '%bCould not create a temporary installer file.%b\n' "$RED" "$RESET"
    return 1
  }
  chmod 600 "$tmp" || true
  printf '\nDownloading the official Homebrew installer...\n'
  if ! zot_homebrew_download "$tmp" || [ ! -s "$tmp" ]; then
    printf '%bHomebrew installer download failed; nothing was executed.%b\n' "$RED" "$RESET"
    rm -f "$tmp"
    record homebrew-install download-failed 1
    return 1
  fi
  if ! head -n 1 "$tmp" | grep -q '^#!/bin/bash'; then
    printf '%bUnexpected installer contents; refusing to execute.%b\n' "$RED" "$RESET"
    rm -f "$tmp"
    record homebrew-install invalid-download 1
    return 1
  fi

  printf 'Running the official Homebrew installer...\n\n'
  zot_homebrew_run "$tmp" || rc=$?
  rm -f "$tmp"
  if [ "$rc" -ne 0 ]; then
    printf '\n%bHomebrew installation failed or was cancelled (exit %s).%b\n' "$RED" "$rc" "$RESET"
    record homebrew-install failed "$rc"
    return 1
  fi

  brew_bin="$(zot_brew_path 2>/dev/null || true)"
  if [ -z "$brew_bin" ] || ! "$brew_bin" --version >/dev/null 2>&1; then
    printf '%bHomebrew installation finished but brew could not be verified.%b\n' "$RED" "$RESET"
    printf 'Follow the Homebrew post-install instructions shown above.\n'
    record homebrew-install unverified 1
    return 1
  fi
  record homebrew-install verified 0
  printf '\n%bHomebrew installed and verified: %s%b\n' "$GREEN" "$brew_bin" "$RESET"
  if ! have brew; then
    printf 'For future Terminal sessions, follow the Homebrew shell PATH instructions printed above.\n'
    printf 'Zot can use the installed brew immediately without changing your shell configuration.\n'
  fi
  return 0
}

catalog_installed(){
  local i="$1" pkg typ app brew_bin
  pkg="${CAT_PKGS[$i]}"; typ="${CAT_TYPES[$i]}"; app="${CAT_APP_NAMES[$i]}"
  brew_bin="$(zot_brew_path 2>/dev/null || true)"
  if [ -n "$brew_bin" ] && [ -n "$pkg" ]; then
    if [ "$typ" = cask ]; then
      "$brew_bin" list --cask "$pkg" >/dev/null 2>&1 && return 0
    elif [ "$typ" = formula ]; then
      "$brew_bin" list --formula "$pkg" >/dev/null 2>&1 && return 0
    fi
  fi
  if [ -n "$app" ]; then
    [ -d "/Applications/$app.app" ] && return 0
    [ -d "$HOME/Applications/$app.app" ] && return 0
  fi
  return 1
}

install_app(){
  local i="$1" pkg typ name url brew_bin rc
  name="${CAT_NAMES[$i]}"; pkg="${CAT_PKGS[$i]}"; typ="${CAT_TYPES[$i]}"
  url="${CAT_URLS[$i]}"
  header
  printf '%b◆ Install %s%b\n\n' "$BOLD$ACCENT" "$name" "$RESET"
  printf '  %s\n\n' "${CAT_DESCS[$i]}"

  if catalog_installed "$i"; then
    printf '%bAlready installed.%b No changes made.\n\n' "$GREEN" "$RESET"
    press_enter
    return 0
  fi

  brew_bin="$(zot_brew_path 2>/dev/null || true)"
  if [ "$typ" != url ] && [ -n "$pkg" ] && [ -z "$brew_bin" ]; then
    # A declined/failed Homebrew setup falls back to the app's official site.
    zot_install_homebrew || true
    brew_bin="$(zot_brew_path 2>/dev/null || true)"
  fi
  if [ "$typ" != url ] && [ -n "$pkg" ] && [ -n "$brew_bin" ]; then
    if [ "$typ" = cask ]; then
      printf 'Method: Homebrew app installer\nCommand: %s install --cask %s\n\n' "$brew_bin" "$pkg"
    else
      printf 'Method: Homebrew command-line package\nCommand: %s install %s\n\n' "$brew_bin" "$pkg"
    fi
    confirm "Download and install $name?" || return 0
    printf '\nInstalling %s... Homebrew output follows.\n\n' "$name"
    rc=0
    if [ "$typ" = cask ]; then
      "$brew_bin" install --cask "$pkg" || rc=$?
    else
      "$brew_bin" install "$pkg" || rc=$?
    fi
    record install "$name" "$rc"
    if [ "$rc" -ne 0 ]; then
      printf '\n%bInstall failed (exit code %s).%b Read the Homebrew error above.\n' "$RED" "$rc" "$RESET"
      printf 'For manual download, visit: %s\n\n' "$url"
      press_enter
      return 1
    fi
    printf '\n%bHomebrew completed successfully: %s%b\n\n' "$GREEN" "$name" "$RESET"
    press_enter
    return 0
  fi

  if [ "$typ" = url ]; then
    printf 'This item is downloaded from its official site.\n'
  else
    printf '%bHomebrew is still unavailable.%b Opening the official app website instead.\n' "$YELLOW" "$RESET"
  fi
  printf 'Official website: %s\n\n' "$url"
  confirm "Open the official download page for $name?" || return 0
  rc=0
  open "$url" || rc=$?
  record open-download "$name" "$rc"
  if [ "$rc" -ne 0 ]; then
    printf '\n%bCould not open your browser (exit code %s).%b\n' "$RED" "$rc" "$RESET"
    printf 'Copy this URL into a browser: %s\n\n' "$url"
    press_enter
    return 1
  fi
  printf '\n%bOfficial download page opened.%b Finish installation in your browser.\n\n' "$GREEN" "$RESET"
  press_enter
}

install_group(){
  local group="$1" i selected
  local -a labels map
  catalog_init
  while :; do
    labels=(); map=()
    for ((i=0;i<${#CAT_NAMES[@]};i++)); do
      [ "${CAT_GROUPS[$i]}" = "$group" ] || continue
      if catalog_installed "$i"; then
        labels+=("${CAT_NAMES[$i]} — installed")
      elif [ "${CAT_TYPES[$i]}" = url ]; then
        labels+=("${CAT_NAMES[$i]} — official website")
      else
        labels+=("${CAT_NAMES[$i]} — download & install")
      fi
      map+=("$i")
    done
    labels+=("Back — app categories")
    menu "$group · Choose an app (Enter to select)" "${labels[@]}"
    selected="$MENU_RESULT"
    [ "$selected" -ge 0 ] || return 0
    [ "$selected" -lt "${#map[@]}" ] || return 0
    install_app "${map[$selected]}" || true
  done
}

install_menu(){
  while :; do
    menu "Download & Install Apps" \
      "Browsers — Zen, Firefox, LibreWolf, Tor" \
      "Utilities — Raycast, Ice, LuLu, iTerm2, more" \
      "Developer — VS Code, GitHub CLI, Python, Node, Xcode" \
      "Install Homebrew — set up the package manager" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) install_group Browsers;;
      1) install_group Utilities;;
      2) install_group Developer;;
      3) header; zot_install_homebrew || true; printf '\n'; press_enter;;
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
  local sip vault firewall gatekeeper seal backup
  sip="$(csrutil status 2>/dev/null | sed -n '1p' || true)"
  vault="$(fdesetup status 2>/dev/null | sed -n '1p' || true)"
  firewall="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | sed -n '1p' || true)"
  gatekeeper="$(spctl --status 2>/dev/null | sed -n '1p' || true)"
  seal="$(diskutil info / 2>/dev/null | awk '/^[[:space:]]*Sealed:/{print $2; exit}' || true)"
  backup="$(tmutil destinationinfo 2>&1 || true)"
  case "$backup" in
    *'No destinations configured'*|'') backup="No destination configured";;
    *'Name'*|*'ID'*|*'Kind'*) backup="Configured (backup not verified)";;
    *) backup="Unable to confirm";;
  esac
  printf '\n%bSecurity & backups (read-only)%b\n' "$BOLD" "$RESET"
  printf '  %-24s %s\n' 'SIP' "${sip:-Unavailable}"
  printf '  %-24s %s\n' 'FileVault' "${vault:-Unavailable}"
  printf '  %-24s %s\n' 'Firewall' "${firewall:-Unavailable}"
  printf '  %-24s %s\n' 'Gatekeeper' "${gatekeeper:-Unavailable}"
  printf '  %-24s %s\n' 'System snapshot sealed' "${seal:-Unavailable}"
  printf '  %-24s %s\n' 'Time Machine' "$backup"
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
  printf 'Saved service disable records: %s (not live status)\n' "$services"
  printf 'Verify live overrides: zot audit\n'
  printf 'Startup items disabled by Zot: %s\n' "$startup"
  local login_tw="OFF" login_cl="OFF"
  login_tweaks_enabled && login_tw="ON"
  login_clean_enabled && login_cl="ON"
  printf 'Login Tweaks Auto Apply: %s\n' "$login_tw"
  printf 'Login Cleaning Auto Run: %s\n' "$login_cl"
  if [ "$login_cl" = ON ]; then
    login_clean_load
    printf '  Login cleanup items: %s\n' "${LOGIN_CLEAN_ITEMS:-not selected}"
  fi
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
  zot homebrew              Set up Homebrew when missing (with approval)
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
    homebrew|brew) header; zot_install_homebrew; printf '\n'; press_enter;;
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
