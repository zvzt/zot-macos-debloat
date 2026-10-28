# Power profiles for supported macOS systems.
# These set only the documented Low Power Mode preference; they never alter
# SIP, GPU clocks, fan controls, device services, or protected system files.
MODE_ORIGINAL="$STATE_DIR/power-original.conf"
MODE_SELECTED="$STATE_DIR/power-selected.txt"

mode_value(){
  local source="$1"
  pmset -g custom 2>/dev/null | awk -v target="$source" '
    /^Battery Power:/ { section="battery"; next }
    /^AC Power:/ { section="ac"; next }
    $1=="lowpowermode" && section==target { print $2; exit }
  '
}

mode_power_state(){
  local battery ac saved
  battery="$(mode_value battery)"; ac="$(mode_value ac)"
  case "$battery" in 0|1) ;; *) battery="unavailable";; esac
  case "$ac" in 0|1) ;; *) ac="unavailable";; esac
  saved="None (using existing settings)"
  [ -f "$MODE_SELECTED" ] && saved="$(cat "$MODE_SELECTED")"
  printf 'Selected Zot mode: %s\n' "$saved"
  printf 'Low Power Mode: battery %s | charger %s\n' "$battery" "$ac"
  printf 'Apple High Power Mode is unavailable on the 2020 M1 MacBook Air.\n'
}

mode_health(){
  printf '\nLive Mac health (read-only)\n'
  printf 'Hardware: %s | macOS %s\n' "$(sysctl -n hw.model 2>/dev/null || echo Mac)" "$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  printf 'Available storage: %s\n' "$(fmt_bytes "$(free_bytes)")"
  printf 'RAM: %s\n' "$(memory_summary)"
  printf 'Swap: %s\n' "$(sysctl vm.swapusage 2>/dev/null | sed -n 's/.*used = \([^ ]*\).*/\1/p')"
  memory_pressure -Q 2>/dev/null | grep 'System-wide memory free percentage' || true
  pmset -g batt 2>/dev/null || true
  if pmset -g therm >/dev/null 2>&1; then
    pmset -g therm 2>/dev/null | head -12
  fi
  printf '\nTop CPU processes\n'
  ps -Ao pid=,pcpu=,pmem=,comm= -r 2>/dev/null | head -8 || true
  printf '\nThis is a readiness check, not an FPS booster or thermal benchmark.\n'
}

mode_backup_original(){
  [ -f "$MODE_ORIGINAL" ] && return 0
  local battery ac tmp
  battery="$(mode_value battery)"; ac="$(mode_value ac)"
  case "$battery:$ac" in 0:0|0:1|1:0|1:1) ;; *)
    echo "Cannot read both macOS Low Power Mode settings; nothing changed." >&2
    return 1
  esac
  mkdir -p "$STATE_DIR"
  tmp="$(mktemp "$STATE_DIR/.power-original.XXXXXX")" || return 1
  chmod 600 "$tmp"
  printf 'battery=%s\nac=%s\n' "$battery" "$ac" > "$tmp"
  mv "$tmp" "$MODE_ORIGINAL"
}

mode_set(){
  local name="$1" battery="$2" ac="$3" applied_b applied_c
  [ -t 0 ] || { echo "Run this change in an interactive Terminal."; return 2; }
  command -v pmset >/dev/null 2>&1 || { echo "pmset unavailable."; return 1; }
  mode_power_state
  printf '\nMode: %s\n' "$name"
  printf 'Set Low Power Mode: battery=%s, charger=%s.\n' "$battery" "$ac"
  printf 'Does not change clock speeds, GPU power, SIP, or background services.\n'
  confirm "Apply this power setting?" || return 0
  mode_backup_original || return 1
  sudo pmset -b lowpowermode "$battery" || return 1
  sudo pmset -c lowpowermode "$ac" || return 1
  applied_b="$(mode_value battery)"; applied_c="$(mode_value ac)"
  if [ "$applied_b:$applied_c" != "$battery:$ac" ]; then
    echo "macOS did not apply both requested settings; inspect with pmset -g custom." >&2
    return 1
  fi
  printf '%s\n' "$name" > "$MODE_SELECTED"
  record power-mode "$name" 0
  echo "Applied. Settings persist across restarts without a login helper."
  mode_power_state
}

mode_restore(){
  local battery ac
  if [ ! -f "$MODE_ORIGINAL" ]; then
    echo "No original power settings were saved. Nothing to restore."
    return 0
  fi
  battery="$(awk -F= '$1=="battery"{print $2}' "$MODE_ORIGINAL")"
  ac="$(awk -F= '$1=="ac"{print $2}' "$MODE_ORIGINAL")"
  case "$battery:$ac" in 0:0|0:1|1:0|1:1) ;; *)
    echo "Saved power settings are invalid. No changes made." >&2
    return 1
  esac
  [ -t 0 ] || { echo "Run restore in an interactive Terminal."; return 2; }
  printf 'Restore original Low Power Mode values: battery=%s, charger=%s\n' "$battery" "$ac"
  confirm "Restore saved power settings?" || return 0
  sudo pmset -b lowpowermode "$battery" || return 1
  sudo pmset -c lowpowermode "$ac" || return 1
  if [ "$(mode_value battery):$(mode_value ac)" != "$battery:$ac" ]; then
    echo "Restore could not be verified. Saved backup retained." >&2
    return 1
  fi
  rm -f "$MODE_SELECTED" "$MODE_ORIGINAL"
  record power-mode restore 0
  echo "Original power settings restored."
  mode_power_state
}

mode_command(){
  case "${1:-}" in
    status|show|info) mode_power_state;;
    health|check) mode_power_state; mode_health;;
    game|gaming|performance) mode_set "Gaming (Low Power Off)" 0 0;;
    battery|save) mode_set "Battery Saver" 1 0;;
    restore|reset|normal) mode_restore;;
    "") if [ -t 0 ] && [ -t 1 ]; then mode_menu; else mode_power_state; fi;;
    *) echo "Use: zot mode [status|health|game|battery|restore]"; return 2;;
  esac
}

mode_menu(){
  while :; do
    menu "Power & Gaming" \
      "Status — current macOS power settings" \
      "Gaming — keep Low Power Mode off" \
      "Battery Saver — reduce power when unplugged" \
      "Restore — undo Zot power changes" \
      "Performance Check — RAM, swap, CPU and power" \
      "Back — main menu"
    case "$MENU_RESULT" in
      0) header; mode_power_state; printf '\n'; press_enter;;
      1) header; mode_set "Gaming (Low Power Off)" 0 0; printf '\n'; press_enter;;
      2) header; mode_set "Battery Saver" 1 0; printf '\n'; press_enter;;
      3) header; mode_restore; printf '\n'; press_enter;;
      4) header; mode_power_state; mode_health; printf '\n'; press_enter;;
      *) return;;
    esac
  done
}
