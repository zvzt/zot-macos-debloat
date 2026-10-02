catalog_init(){
  CAT_NAMES=("Firefox" "Google Chrome" "Brave Browser" "Arc" "Raycast" "Rectangle" "Pearcleaner" "IINA" "VLC" "Visual Studio Code" "iTerm2" "Discord" "Slack" "Zoom" "Spotify" "OBS Studio" "LosslessCut" "Steam" "GitHub CLI" "Python" "Node.js" "Mole")
  CAT_PKGS=("firefox" "google-chrome" "brave-browser" "arc" "raycast" "rectangle" "pearcleaner" "iina" "vlc" "visual-studio-code" "iterm2" "discord" "slack" "zoom" "spotify" "obs" "losslesscut" "steam" "gh" "python" "node" "mole")
  CAT_TYPES=(cask cask cask cask cask cask cask cask cask cask cask cask cask cask cask cask cask cask formula formula formula formula)
  CAT_GROUPS=(Browsers Browsers Browsers Browsers Utilities Utilities Utilities Media Media Developer Developer Communication Communication Communication Media Media Media Gaming Developer Developer Developer Utilities)
  CAT_URLS=("https://www.mozilla.org/firefox/" "https://www.google.com/chrome/" "https://brave.com/download/" "https://arc.net/" "https://www.raycast.com/" "https://rectangleapp.com/" "https://itsalin.com/appInfo/?id=pearcleaner" "https://iina.io/" "https://www.videolan.org/vlc/" "https://code.visualstudio.com/" "https://iterm2.com/" "https://discord.com/download" "https://slack.com/downloads/mac" "https://zoom.us/download" "https://www.spotify.com/download/" "https://obsproject.com/" "https://github.com/mifi/lossless-cut" "https://store.steampowered.com/about/" "https://cli.github.com/" "https://www.python.org/downloads/macos/" "https://nodejs.org/" "https://github.com/tw93/Mole")
}
install_group(){
  local group="$1"; catalog_init; local -a labels map; labels=(); map=(); local i state pkg typ
  for ((i=0;i<${#CAT_NAMES[@]};i++)); do
    [ "${CAT_GROUPS[$i]}" = "$group" ] || continue; state=""
    if have brew; then pkg="${CAT_PKGS[$i]}"; typ="${CAT_TYPES[$i]}"; if [ "$typ" = cask ]; then brew list --cask "$pkg" >/dev/null 2>&1 && state=" · installed"; else brew list "$pkg" >/dev/null 2>&1 && state=" · installed"; fi; fi
    labels+=("${CAT_NAMES[$i]}$state"); map+=("$i")
  done
  multi_menu "Install · $group" "${labels[@]}" || return; [ -n "$MULTI_RESULT" ] || return
  header
  if have brew; then printf '%bHomebrew detected. Selected apps will install through Homebrew.%b\n\n' "$GREEN" "$RESET"
  else printf '%bHomebrew is not installed. Zot will open official download pages instead; it will not install a package manager.%b\n\n' "$YELLOW" "$RESET"; fi
  local idx real; for idx in $MULTI_RESULT; do real="${map[$idx]}"; printf '  %s\n' "${CAT_NAMES[$real]}"; done
  printf '\n'; confirm "Continue?" || return
  for idx in $MULTI_RESULT; do
    real="${map[$idx]}"; pkg="${CAT_PKGS[$real]}"; typ="${CAT_TYPES[$real]}"; printf '\n%b→ %s%b\n' "$CYAN" "${CAT_NAMES[$real]}" "$RESET"
    if have brew; then if [ "$typ" = cask ]; then brew install --cask "$pkg" || true; else brew install "$pkg" || true; fi; record install "${CAT_NAMES[$real]}" 0
    else open "${CAT_URLS[$real]}" >/dev/null 2>&1 || true; fi
  done
  printf '\n%bInstall action complete.%b\n\n' "$GREEN" "$RESET"; press_enter
}
install_menu(){ while :; do menu "Install Apps" "Browsers" "Utilities" "Developer" "Communication" "Media" "Gaming" "Back"; case "$MENU_RESULT" in 0) install_group Browsers;; 1) install_group Utilities;; 2) install_group Developer;; 3) install_group Communication;; 4) install_group Media;; 5) install_group Gaming;; *) return;; esac; done; }
history_screen(){ header; printf '%bRecent Zot Operations%b\n\n' "$BOLD" "$RESET"; if [ -s "$HISTORY_FILE" ]; then tail -40 "$HISTORY_FILE" | awk -F'|' '{printf "  %-19s  %-18s  %s\n",$1,$2,$3}'; else echo "  No operations recorded yet."; fi; printf '\n'; press_enter; }
doctor_screen(){
  header; printf '%bSystem Doctor%b\n\n' "$BOLD" "$RESET"
  local mac arch free pct swap pressure; mac="$(sw_vers -productVersion 2>/dev/null || echo unknown)"; arch="$(uname -m)"; free="$(free_bytes)"
  pct="$(df -k / 2>/dev/null | awk 'NR==2{gsub("%","",$5);print $5+0}')"; swap="$(sysctl vm.swapusage 2>/dev/null | sed -E 's/.*used = ([0-9.]+[MG]).*/\1/' | head -1)"; pressure="$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage/{print $5}' | tr -d '%' | head -1)"
  printf '  %-24s %s\n' 'macOS' "$mac"; printf '  %-24s %s\n' 'Architecture' "$arch"; printf '  %-24s %s\n' 'Free disk' "$(fmt_bytes "$free")"; printf '  %-24s %s%% used\n' 'Startup disk' "$pct"; printf '  %-24s %s\n' 'Swap used' "${swap:-unknown}"; printf '  %-24s %s\n' 'Memory free' "${pressure:-unknown}%"; printf '  %-24s %s\n' 'Spotlight' "$(mdutil -s / 2>/dev/null | tail -1 | xargs)"; printf '  %-24s %s\n' 'Homebrew' "$(have brew && brew --version | head -1 || echo 'not installed')"
  printf '\n%bNotes%b\n' "$BOLD" "$RESET"; [ "$free" -lt 21474836480 ] && printf '  %b! Less than 20 GB free; low free space can hurt macOS performance.%b\n' "$YELLOW" "$RESET" || printf '  %b✓ Disk free space looks reasonable.%b\n' "$GREEN" "$RESET"; case "${swap:-0}" in *G) printf '  %b• Swap is in use. Check Status for sustained high-memory processes.%b\n' "$GRAY" "$RESET";; esac; printf '\n'; press_enter
}
update_zot(){ header; printf '%bUpdating Zot...%b\n\n' "$BOLD" "$RESET"; local url="https://api.github.com/repositories/1356850441/contents/install.sh?ref=main"; if curl -fsSL -H 'Accept: application/vnd.github.raw+json' "$url" | bash; then printf '\n%bUpdate complete.%b\n' "$GREEN" "$RESET"; else printf '\n%bUpdate failed.%b\n' "$RED" "$RESET"; fi; printf '\n'; press_enter; }
tools_menu(){ while :; do menu "Tools" "System Doctor" "Operation History" "Update Zot" "Open Activity Monitor" "Open Storage Settings" "Back"; case "$MENU_RESULT" in 0) doctor_screen;; 1) history_screen;; 2) update_zot;; 3) open -a 'Activity Monitor' >/dev/null 2>&1 || true;; 4) open 'x-apple.systempreferences:com.apple.settings.Storage' >/dev/null 2>&1 || true;; *) return;; esac; done; }
hub(){
  while :; do
    basic_snapshot; MENU_SUBTITLE="$SNAP_MODEL · $SNAP_FREE free · RAM $SNAP_MEM"
    menu "Hub" "Dashboard / Performance" "Scan" "Clean" "Analyze Storage" "Apps & Leftovers" "Startup & Background" "Optimize" "Install Apps" "Services & Features" "Tools" "Quit"
    MENU_SUBTITLE=""
    case "$MENU_RESULT" in 0) status_screen;; 1) scan_screen;; 2) clean_menu;; 3) analyze_menu;; 4) apps_screen;; 5) startup_screen;; 6) optimize_screen;; 7) install_menu;; 8) services_screen;; 9) tools_menu;; *) clear; return;; esac
  done
}
usage(){
  cat <<EOF
Zot $VERSION

Usage:
  zot                  Open the interactive hub
  zot status           Live performance dashboard
  zot scan             Read-only cleanup/storage scan
  zot clean            Open cleanup hub
  zot analyze          Open storage analyzer
  zot apps             App uninstaller + leftovers
  zot startup          Startup/background manager
  zot optimize         Maintenance/optimization hub
  zot install          Curated app installer
  zot services         macOS service/profile controls
  zot doctor           System health checks
  zot history          Show operation history
  zot restore          Restore Zot-managed service/startup changes
  zot update           Update Zot
  zot version          Print version
EOF
}
restore_all(){
  header; confirm "Restore all startup and service changes recorded by Zot?" || return 0; services_restore
  if [ -s "$STARTUP_STATE" ]; then
    while IFS='|' read -r kind label path; do
      [ -n "$label" ] || continue
      if [ "$kind" = user ]; then launchctl enable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true; [ -f "$path" ] && launchctl bootstrap "gui/$UID_NUM" "$path" >/dev/null 2>&1 || true
      else sudo launchctl enable "system/$label" >/dev/null 2>&1 || true; [ -f "$path" ] && sudo launchctl bootstrap system "$path" >/dev/null 2>&1 || true; fi
    done < "$STARTUP_STATE"; : > "$STARTUP_STATE"
  fi
  printf '\n%bRestore complete. Restart macOS if a restored service does not return immediately.%b\n\n' "$GREEN" "$RESET"
}
main(){
  load_config
  case "${1:-}" in
    '') if [ -t 0 ] && [ -t 1 ]; then hub; else usage; fi;;
    status) status_screen;; scan) scan_screen;; clean) clean_menu;; analyze) analyze_menu;; apps) apps_screen;; startup) startup_screen;; optimize) optimize_screen;; install) install_menu;; services) services_screen;; doctor) doctor_screen;; history) history_screen;; restore) restore_all;; update) update_zot;; reapply-user) services_apply >/dev/null 2>&1 || true;; version|--version|-v) echo "$VERSION";; help|--help|-h) usage;; *) usage; return 2;;
  esac
}
