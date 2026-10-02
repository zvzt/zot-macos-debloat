LOGIN_TWEAKS_FILE="$STATE_DIR/login-tweaks.conf"
LOGIN_CLEAN_FILE="$STATE_DIR/login-cleaning.conf"
LOGIN_TWEAK_AGENT="$HOME/Library/LaunchAgents/com.zot.login.tweaks.plist"
LOGIN_CLEAN_AGENT="$HOME/Library/LaunchAgents/com.zot.login.cleaning.plist"
LOGIN_SYSTEM_DAEMON="/Library/LaunchDaemons/com.zot.login.system-tweaks.plist"

login_tweak_load(){
  LOGIN_PROFILE="balanced"
  LOGIN_SIRI="keep"
  LOGIN_INTELLIGENCE="keep"
  LOGIN_SPOTLIGHT="keep"
  [ -f "$LOGIN_TWEAKS_FILE" ] || return 0
  while IFS='=' read -r k v; do
    case "$k" in
      profile) LOGIN_PROFILE="$v";;
      siri) LOGIN_SIRI="$v";;
      intelligence) LOGIN_INTELLIGENCE="$v";;
      spotlight) LOGIN_SPOTLIGHT="$v";;
    esac
  done < "$LOGIN_TWEAKS_FILE"
}

login_tweak_save(){
  mkdir -p "$STATE_DIR"
  cat > "$LOGIN_TWEAKS_FILE" <<EOF
profile=$LOGIN_PROFILE
siri=$LOGIN_SIRI
intelligence=$LOGIN_INTELLIGENCE
spotlight=$LOGIN_SPOTLIGHT
EOF
}

login_clean_load(){
  LOGIN_CLEAN_ITEMS=""
  [ -f "$LOGIN_CLEAN_FILE" ] || return 0
  LOGIN_CLEAN_ITEMS="$(awk -F= '$1=="items"{sub(/^items=/,"");print}' "$LOGIN_CLEAN_FILE" 2>/dev/null || true)"
}

login_clean_save(){
  mkdir -p "$STATE_DIR"
  printf 'items=%s
' "$LOGIN_CLEAN_ITEMS" > "$LOGIN_CLEAN_FILE"
}

login_tweaks_enabled(){ [ -f "$LOGIN_TWEAK_AGENT" ]; }
login_clean_enabled(){ [ -f "$LOGIN_CLEAN_AGENT" ]; }
login_system_enabled(){ [ -f "$LOGIN_SYSTEM_DAEMON" ]; }

login_profile_labels(){
  case "$LOGIN_PROFILE" in
    balanced) read_preset "$(preset_file balanced)";;
    aggressive)
      read_preset "$(preset_file balanced)"
      read_preset "$(preset_file aggressive)"
      ;;
  esac
  [ "$LOGIN_SIRI" = disable ] && read_preset "$(preset_file siri)"
  [ "$LOGIN_INTELLIGENCE" = disable ] && read_preset "$(preset_file intelligence)"
}

login_apply_tweaks(){
  local mode="$1" labels label kind
  login_tweak_load
  labels="$(login_profile_labels | awk '!seen[$0]++')"

  while IFS= read -r label; do
    [ -n "$label" ] || continue
    kind="$(plist_kind "$label" | head -1)"
    [ "$kind" = "$mode" ] || continue

    if [ "$mode" = user ]; then
      launchctl disable "gui/$UID_NUM/$label" >/dev/null 2>&1 || true
      launchctl bootout "gui/$UID_NUM/$label" >/dev/null 2>&1 || true
    else
      launchctl disable "system/$label" >/dev/null 2>&1 || true
      launchctl bootout "system/$label" >/dev/null 2>&1 || true
    fi
  done <<< "$labels"

  if [ "$mode" = system ] && [ "$LOGIN_SPOTLIGHT" = off ]; then
    mdutil -i off / >/dev/null 2>&1 || true
  fi
}

write_user_agent(){
  local path="$1" label="$2" action="$3" out="$4"
  mkdir -p "$HOME/Library/LaunchAgents" "$STATE_DIR"
  cat > "$path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BASE_DIR/zot</string>
    <string>$action</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>ZOT_HOME</key>
    <string>$BASE_DIR</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/$out.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/$out-error.log</string>
</dict>
</plist>
EOF
  chmod 600 "$path"
}

write_system_tweak_daemon(){
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.zot.login.system-tweaks</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BASE_DIR/zot</string>
    <string>login-run-system</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>ZOT_HOME</key>
    <string>$BASE_DIR</string>
    <key>PATH</key>
    <string>/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>ProcessType</key>
  <string>Background</string>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/login-system.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/login-system-error.log</string>
</dict>
</plist>
EOF
  sudo mkdir -p /Library/LaunchDaemons
  sudo cp "$tmp" "$LOGIN_SYSTEM_DAEMON"
  sudo chown root:wheel "$LOGIN_SYSTEM_DAEMON"
  sudo chmod 644 "$LOGIN_SYSTEM_DAEMON"
  rm -f "$tmp"
}

login_tweaks_enable(){
  login_tweak_load
  write_user_agent "$LOGIN_TWEAK_AGENT" "com.zot.login.tweaks" "login-run-tweaks" "login-tweaks"

  launchctl bootout "gui/$UID_NUM" "$LOGIN_TWEAK_AGENT" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$UID_NUM" "$LOGIN_TWEAK_AGENT" >/dev/null 2>&1 || true

  write_system_tweak_daemon
  sudo launchctl bootout system "$LOGIN_SYSTEM_DAEMON" >/dev/null 2>&1 || true
  sudo launchctl bootstrap system "$LOGIN_SYSTEM_DAEMON" >/dev/null 2>&1 || true

  record login-enable tweaks 0
}

login_tweaks_disable(){
  launchctl bootout "gui/$UID_NUM" "$LOGIN_TWEAK_AGENT" >/dev/null 2>&1 || true
  rm -f "$LOGIN_TWEAK_AGENT"

  if [ -f "$LOGIN_SYSTEM_DAEMON" ]; then
    sudo launchctl bootout system "$LOGIN_SYSTEM_DAEMON" >/dev/null 2>&1 || true
    sudo rm -f "$LOGIN_SYSTEM_DAEMON"
  fi
  record login-disable tweaks 0
}

login_clean_enable(){
  login_clean_load
  [ -n "$LOGIN_CLEAN_ITEMS" ] || {
    printf '%bNo cleaning items are selected.%b
' "$YELLOW" "$RESET"
    return 1
  }

  write_user_agent "$LOGIN_CLEAN_AGENT" "com.zot.login.cleaning" "login-run-cleaning" "login-cleaning"
  launchctl bootout "gui/$UID_NUM" "$LOGIN_CLEAN_AGENT" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$UID_NUM" "$LOGIN_CLEAN_AGENT" >/dev/null 2>&1 || true
  record login-enable cleaning 0
}

login_clean_disable(){
  launchctl bootout "gui/$UID_NUM" "$LOGIN_CLEAN_AGENT" >/dev/null 2>&1 || true
  rm -f "$LOGIN_CLEAN_AGENT"
  record login-disable cleaning 0
}

login_disable_all(){
  login_tweaks_disable || true
  login_clean_disable || true
}

login_clean_run(){
  login_clean_load
  local item p proc

  for item in $LOGIN_CLEAN_ITEMS; do
    case "$item" in
      caches)
        clear_dir "$HOME/Library/Caches"
        ;;
      logs)
        clear_dir "$HOME/Library/Logs"
        ;;
      trash)
        clear_dir "$HOME/.Trash"
        ;;
      xcode)
        clear_dir "$HOME/Library/Developer/Xcode/DerivedData"
        ;;
      browsers)
        browser_targets
        local i
        for ((i=0;i<${#BROWSER_NAMES[@]};i++)); do
          p="${BROWSER_PATHS[$i]}"
          proc="${BROWSER_PROCS[$i]}"
          [ -d "$p" ] || continue
          if pgrep -x "$proc" >/dev/null 2>&1 || pgrep -f "/$proc" >/dev/null 2>&1; then
            continue
          fi
          clear_dir "$p"
        done
        ;;
      homebrew)
        have brew && brew cleanup -s >/dev/null 2>&1 || true
        ;;
      pip)
        have python3 && python3 -m pip cache purge >/dev/null 2>&1 || true
        ;;
      npm)
        have npm && npm cache clean --force >/dev/null 2>&1 || true
        ;;
      pnpm)
        have pnpm && pnpm store prune >/dev/null 2>&1 || true
        ;;
      yarn)
        have yarn && yarn cache clean >/dev/null 2>&1 || true
        ;;
      quicklook)
        qlmanage -r cache >/dev/null 2>&1 || true
        ;;
    esac
    record login-clean "$item" 0
  done
}

login_tweaks_configure(){
  login_tweak_load

  menu "Login Items · Tweaks · Profile"     "Balanced — lower-impact service reductions"     "Aggressive — more optional services disabled"     "None — only use optional tweaks below"     "Back — cancel"
  case "$MENU_RESULT" in
    0) LOGIN_PROFILE=balanced;;
    1) LOGIN_PROFILE=aggressive;;
    2) LOGIN_PROFILE=none;;
    *) return;;
  esac

  menu "Login Items · Siri"     "Keep — do not auto-disable Siri services"     "Disable — reapply Siri service tweaks at login"     "Back — cancel"
  case "$MENU_RESULT" in
    0) LOGIN_SIRI=keep;;
    1) LOGIN_SIRI=disable;;
    *) return;;
  esac

  menu "Login Items · Apple Intelligence"     "Keep — do not auto-disable AI services"     "Disable — reapply Apple Intelligence service tweaks"     "Back — cancel"
  case "$MENU_RESULT" in
    0) LOGIN_INTELLIGENCE=keep;;
    1) LOGIN_INTELLIGENCE=disable;;
    *) return;;
  esac

  menu "Login Items · Spotlight"     "Keep — leave Spotlight indexing alone"     "Disable — reapply Spotlight indexing off at boot"     "Back — cancel"
  case "$MENU_RESULT" in
    0) LOGIN_SPOTLIGHT=keep;;
    1) LOGIN_SPOTLIGHT=off;;
    *) return;;
  esac

  login_tweak_save

  header
  printf '%b◆ Login Tweaks Saved%b

' "$BOLD$ACCENT" "$RESET"
  printf '  Profile              %s
' "$LOGIN_PROFILE"
  printf '  Siri                 %s
' "$LOGIN_SIRI"
  printf '  Apple Intelligence   %s
' "$LOGIN_INTELLIGENCE"
  printf '  Spotlight            %s

' "$LOGIN_SPOTLIGHT"
  printf '%bmacOS can re-enable some services after restarts or system updates.%b
' "$GRAY" "$RESET"
  printf '%bAuto Apply runs once at boot/login and exits; it is not a constantly running process.%b

' "$GRAY" "$RESET"

  if confirm "Enable Auto Apply for these tweaks at login?"; then
    login_tweaks_enable
    printf '
%bTweaks Auto Apply is ON.%b

' "$GREEN" "$RESET"
  else
    login_tweaks_disable
    printf '
%bTweaks Auto Apply is OFF. Your selections were still saved.%b

' "$YELLOW" "$RESET"
  fi
  press_enter
}

login_clean_configure(){
  local -a labels keys
  labels=(
    "User app caches — rebuildable application cache files"
    "User logs — application diagnostic logs"
    "Trash — permanently empty your Trash"
    "Xcode DerivedData — rebuildable Xcode build data"
    "Browser caches — Zen, Firefox, LibreWolf disk caches"
    "Homebrew cleanup — old versions and downloaded packages"
    "pip cache — Python package download cache"
    "npm cache — Node package download cache"
    "pnpm store — unused pnpm packages"
    "Yarn cache — Yarn package download cache"
    "Quick Look cache — Finder preview thumbnails"
  )
  keys=(caches logs trash xcode browsers homebrew pip npm pnpm yarn quicklook)

  multi_menu "Login Items · Cleaning" "${labels[@]}" || return
  LOGIN_CLEAN_ITEMS=""
  local idx
  for idx in $MULTI_RESULT; do
    LOGIN_CLEAN_ITEMS="$LOGIN_CLEAN_ITEMS ${keys[$idx]}"
  done
  LOGIN_CLEAN_ITEMS="$(trim "$LOGIN_CLEAN_ITEMS")"
  login_clean_save

  header
  printf '%b◆ Login Cleaning Saved%b

' "$BOLD$ACCENT" "$RESET"
  if [ -n "$LOGIN_CLEAN_ITEMS" ]; then
    printf '  Selected: %s

' "$LOGIN_CLEAN_ITEMS"
  else
    printf '  No cleanup categories selected.

'
  fi
  printf '%bAutomatic cache cleanup can make the first launch of apps slower because caches must rebuild.%b
' "$YELLOW" "$RESET"
  printf '%bCleaning runs once when you sign in and then exits.%b

' "$GRAY" "$RESET"

  if [ -z "$LOGIN_CLEAN_ITEMS" ]; then
    login_clean_disable
    printf '%bCleaning Auto Run is OFF because nothing is selected.%b

' "$YELLOW" "$RESET"
  elif confirm "Enable automatic cleaning at login?"; then
    login_clean_enable
    printf '
%bCleaning Auto Run is ON.%b

' "$GREEN" "$RESET"
  else
    login_clean_disable
    printf '
%bCleaning Auto Run is OFF. Your selections were still saved.%b

' "$YELLOW" "$RESET"
  fi
  press_enter
}

login_status_plain(){
  login_tweak_load
  login_clean_load
  local tw="OFF" cl="OFF" sys="OFF"
  login_tweaks_enabled && tw="ON"
  login_clean_enabled && cl="ON"
  login_system_enabled && sys="ON"

  printf 'Tweaks Auto Apply: %s
' "$tw"
  printf '  Profile: %s
' "$LOGIN_PROFILE"
  printf '  Siri: %s
' "$LOGIN_SIRI"
  printf '  Apple Intelligence: %s
' "$LOGIN_INTELLIGENCE"
  printf '  Spotlight: %s
' "$LOGIN_SPOTLIGHT"
  printf '  System boot helper: %s
' "$sys"
  printf 'Cleaning Auto Run: %s
' "$cl"
  printf '  Items: %s
' "${LOGIN_CLEAN_ITEMS:-none}"
}

login_status_screen(){
  header
  printf '%b◆ Login Items Status%b

' "$BOLD$ACCENT" "$RESET"
  login_status_plain | sed 's/^/  /'
  printf '
'
  press_enter
}

login_toggle_tweaks(){
  if login_tweaks_enabled; then
    header
    printf '%bTweaks Auto Apply is currently ON.%b

' "$GREEN" "$RESET"
    printf '%bTurning it off only removes auto-run. It does not restore tweaks already applied.%b

' "$GRAY" "$RESET"
    if confirm "Turn Tweaks Auto Apply OFF?"; then login_tweaks_disable; fi
  else
    login_tweak_load
    header
    printf '%bTweaks Auto Apply is currently OFF.%b

' "$YELLOW" "$RESET"
    printf 'Saved profile: %s · Siri %s · AI %s · Spotlight %s

' "$LOGIN_PROFILE" "$LOGIN_SIRI" "$LOGIN_INTELLIGENCE" "$LOGIN_SPOTLIGHT"
    if confirm "Turn Tweaks Auto Apply ON?"; then login_tweaks_enable; fi
  fi
  printf '
'
  press_enter
}

login_toggle_clean(){
  login_clean_load
  if login_clean_enabled; then
    header
    printf '%bCleaning Auto Run is currently ON.%b

' "$GREEN" "$RESET"
    if confirm "Turn Cleaning Auto Run OFF?"; then login_clean_disable; fi
  else
    header
    printf '%bCleaning Auto Run is currently OFF.%b

' "$YELLOW" "$RESET"
    printf 'Saved items: %s

' "${LOGIN_CLEAN_ITEMS:-none}"
    if [ -z "$LOGIN_CLEAN_ITEMS" ]; then
      printf '%bConfigure Cleaning first so Zot knows what to clean.%b

' "$YELLOW" "$RESET"
    elif confirm "Turn Cleaning Auto Run ON?"; then
      login_clean_enable
    fi
  fi
  printf '
'
  press_enter
}

login_hub(){
  while :; do
    login_tweak_load
    login_clean_load
    local tw="OFF" cl="OFF"
    login_tweaks_enabled && tw="ON"
    login_clean_enabled && cl="ON"
    MENU_SUBTITLE="Tweaks $tw · Cleaning $cl"

    menu "Login Items"       "Tweaks — choose what Zot reapplies at boot/login"       "Cleaning — choose what Zot cleans each login"       "Toggle Tweaks Auto Apply — currently $tw"       "Toggle Cleaning Auto Run — currently $cl"       "Status — view saved selections and login files"       "Run Tweaks Now — reapply saved login tweak profile"       "Run Cleaning Now — clean saved login categories"       "Disable All — remove Zot login/boot helpers"       "Back — return to the hub"
    MENU_SUBTITLE=""

    case "$MENU_RESULT" in
      0) login_tweaks_configure;;
      1) login_clean_configure;;
      2) login_toggle_tweaks;;
      3) login_toggle_clean;;
      4) login_status_screen;;
      5)
        header
        printf '%bReapplying saved user/system login tweaks...%b

' "$BOLD" "$RESET"
        login_apply_tweaks user
        sudo env HOME="$HOME" ZOT_HOME="$BASE_DIR" "$BASE_DIR/zot" login-run-system
        printf '%bDone.%b

' "$GREEN" "$RESET"
        press_enter
        ;;
      6)
        header
        printf '%bRunning saved login cleaning now...%b

' "$BOLD" "$RESET"
        login_clean_run
        printf '%bDone.%b

' "$GREEN" "$RESET"
        press_enter
        ;;
      7)
        header
        if confirm "Disable all Zot login items?"; then
          login_disable_all
          printf '
%bAll Zot login items are OFF.%b

' "$GREEN" "$RESET"
        fi
        press_enter
        ;;
      *) return;;
    esac
  done
}
