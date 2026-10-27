# Zot full maintenance: updates first, then reviewed cleanup and a final refresh.
# Never call this from an automatic login job.
full_step() {
  printf '\n==> %s\n' "$1"
}
full_run() {
  "$@" || { printf 'Warning: step failed: %s\n' "$*"; return 1; }
}
full_maintenance() {
  local mode="${1:-run}" failures=0
  [ "$(uname -s)" = Darwin ] || { echo "macOS only."; return 1; }
  if [ "$mode" = dry-run ]; then
    cat <<'PLAN'
Zot Full Maintenance (preview; no changes)
1. Update Homebrew metadata, formulae and casks (if installed).
2. Update Mac App Store apps via mas (if installed), check Apple software updates.
3. Run Homebrew cleanup and Mole clean/optimize (if installed).
4. Refresh DNS, Quick Look, Finder, Dock, SystemUIServer, and CoreAudio.
5. Optionally quit open GUI apps and restart macOS.
Mole and Zot may permanently remove rebuildable caches and Trash contents.
Apps not managed by Homebrew or mas may require their own updater.
Nothing deletes personal documents, app settings, drivers, or swap files.
PLAN
    return 0
  fi
  [ "$mode" = run ] || { echo "Usage: zot full [--dry-run]"; return 2; }
  echo "Zot Full Maintenance for Apple Silicon / macOS"
  echo "Save your work before starting. Updates can change installed apps."
  echo "Mole clean may permanently empty Trash and delete caches."
  confirm "Run app updates, system maintenance and reviewed cleanup?" || return 0

  full_step "Homebrew and managed apps"
  if have brew; then
    full_run brew update || failures=$((failures+1))
    full_run brew upgrade --formula || failures=$((failures+1))
    full_run brew upgrade --cask || failures=$((failures+1))
    full_run brew cleanup || failures=$((failures+1))
    full_run brew autoremove || failures=$((failures+1))
  else
    echo "Homebrew unavailable; skipping. Not installing a package manager."
  fi
  if have mas; then
    full_run mas upgrade || failures=$((failures+1))
  else
    echo "mas unavailable; Mac App Store apps must be updated through App Store."
  fi

  full_step "Apple system updates"
  if have softwareupdate; then
    softwareupdate -l || failures=$((failures+1))
    if confirm "Install available macOS updates now? (may require a separate restart)"; then
      sudo softwareupdate -ia || failures=$((failures+1))
    fi
  fi

  full_step "Clean caches and optimize"
  if have mo; then
    echo "Mole performs its own safety checks and confirmation prompts."
    full_run mo clean || failures=$((failures+1))
    full_run mo optimize || failures=$((failures+1))
  else
    echo "Mole unavailable. Install with: brew install mole"
  fi
  if confirm "Also run Zot user-cache/log/Trash cleanup (may duplicate Mole)?"; then
    # Zot's existing cleaner reviews locations and confirms deletion.
    clean_basic quick
  fi

  full_step "Refresh networking and user interface"
  if have dscacheutil; then full_run dscacheutil -flushcache || failures=$((failures+1)); fi
  sudo killall -HUP mDNSResponder 2>/dev/null || true
  if have qlmanage; then qlmanage -r cache >/dev/null 2>&1 || true; fi
  for service in Dock Finder SystemUIServer; do
    killall "$service" 2>/dev/null || true
  done
  echo "CoreAudio restart temporarily interrupts sound and calls."
  if confirm "Restart CoreAudio now?"; then
    sudo killall coreaudiod 2>/dev/null || { echo "CoreAudio restart skipped/failed."; failures=$((failures+1)); }
  fi

  full_step "Final session refresh"
  echo "Quitting apps can cause unsaved work to be lost. Save everything first."
  if confirm "Ask open GUI apps to quit gracefully?"; then
    osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "System Events"
  set quitApps to name of every application process whose background only is false
end tell
repeat with appName in quitApps
  if (appName as text) is not "Finder" and (appName as text) is not "Terminal" and (appName as text) is not "iTerm2" then
    try
      tell application (appName as text) to quit
    end try
  end if
end repeat
APPLESCRIPT
  fi
  record full-maintenance "finished; failures=$failures" 0
  echo "Maintenance completed with $failures reported step failures."
  if confirm "Restart your Mac now? Save all open work first."; then
    osascript -e 'tell application "System Events" to restart' || echo "Restart canceled or denied."
  else
    echo "Reboot skipped. You can restart later from the Apple menu."
  fi
}
