have(){ command -v "$1" >/dev/null 2>&1; }
run_quiet(){ "$@" >/dev/null 2>&1; }
trim(){ printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
fmt_bytes(){
  awk -v n="${1:-0}" 'BEGIN{split("B KB MB GB TB",u," "); i=1; while(n>=1024&&i<5){n/=1024;i++} if(i==1)printf "%.0f %s",n,u[i]; else printf "%.1f %s",n,u[i]}'
}
path_kb(){
  [ -e "$1" ] || { echo 0; return; }
  du -sk "$1" 2>/dev/null | awk 'NR==1{print $1+0}'
}
path_bytes(){ echo $(( $(path_kb "$1") * 1024 )); }
free_bytes(){ local k; k="$(df -k / 2>/dev/null | awk 'NR==2{print $4}')"; [ -n "$k" ] || k=0; echo $((k * 1024)); }
record(){
  mkdir -p "$STATE_DIR"
  printf '%s|%s|%s|%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "${2//|/ }" "${3:-0}" >> "$HISTORY_FILE"
}

apply_theme(){
  case "${THEME:-cyan}" in
    purple) ACCENT="${ESC}[38;5;177m"; ACCENT2="${ESC}[38;5;141m";;
    blue)   ACCENT="${ESC}[38;5;75m";  ACCENT2="${ESC}[38;5;111m";;
    green)  ACCENT="${ESC}[38;5;78m";  ACCENT2="${ESC}[38;5;114m";;
    amber)  ACCENT="${ESC}[38;5;221m"; ACCENT2="${ESC}[38;5;215m";;
    red)    ACCENT="${ESC}[38;5;203m"; ACCENT2="${ESC}[38;5;210m";;
    mono)   ACCENT="${ESC}[38;5;255m"; ACCENT2="${ESC}[38;5;250m";;
    *)      THEME="cyan"; ACCENT="${ESC}[38;5;81m"; ACCENT2="${ESC}[38;5;75m";;
  esac
  CYAN="$ACCENT"
  BLUE="$ACCENT2"
}

confirm(){
  local p="$1" ans
  while :; do
    printf '%b%s [Y/N]: %b' "$YELLOW" "$p" "$RESET"
    IFS= read -r ans
    case "$ans" in
      y|Y|yes|YES) return 0;;
      n|N|no|NO) return 1;;
      *) printf '%bPlease type Y or N.%b\n' "$GRAY" "$RESET";;
    esac
  done
}
press_enter(){ printf '%bPress Enter to continue...%b' "$GRAY" "$RESET"; IFS= read -r _; }

header(){
  apply_theme
  clear
  printf '%b╭────────────────────────────────────────────────────────────────────╮%b\n' "$ACCENT" "$RESET"
  printf '%b│%b  %bZOT%b  %bmacOS utility hub%b                                      %bv%s%b  %b│%b\n' "$ACCENT" "$RESET" "$BOLD$ACCENT" "$RESET" "$GRAY" "$RESET" "$GRAY" "$VERSION" "$RESET" "$ACCENT" "$RESET"
  printf '%b╰────────────────────────────────────────────────────────────────────╯%b\n\n' "$ACCENT" "$RESET"
}
cleanup_terminal(){ [ -t 1 ] || return 0; printf '%b\033[?25h%b' "$RESET" "$RESET"; stty echo 2>/dev/null || true; }
trap cleanup_terminal EXIT INT TERM

load_config(){
  PROFILE="balanced"; SIRI="keep"; INTELLIGENCE="keep"; SPOTLIGHT="keep"; THEME="cyan"
  [ -f "$CONFIG_FILE" ] || { apply_theme; return 0; }
  while IFS='=' read -r k v; do
    case "$k" in
      profile) PROFILE="$v";;
      siri) SIRI="$v";;
      intelligence) INTELLIGENCE="$v";;
      spotlight) SPOTLIGHT="$v";;
      theme) THEME="$v";;
    esac
  done < "$CONFIG_FILE"
  apply_theme
}
save_config(){
  mkdir -p "$BASE_DIR"
  cat > "$CONFIG_FILE" <<EOF
profile=$PROFILE
siri=$SIRI
intelligence=$INTELLIGENCE
spotlight=$SPOTLIGHT
theme=$THEME
EOF
}

menu(){
  local title="$1"; shift
  local selected=0 key seq i count=$#
  MENU_RESULT=-1
  while :; do
    header
    printf '%b◆ %s%b\n' "$BOLD$ACCENT" "$title" "$RESET"
    [ -n "${MENU_SUBTITLE:-}" ] && printf '%b  %s%b\n' "$GRAY" "$MENU_SUBTITLE" "$RESET"
    printf '\n'
    i=0
    for item in "$@"; do
      if [ "$i" -eq "$selected" ]; then
        printf '  %b▸ %-62s%b\n' "$ACCENT$BOLD" "$item" "$RESET"
      else
        printf '    %-62s\n' "$item"
      fi
      i=$((i+1))
    done
    printf '\n%b  ↑/↓ move   Enter select   q back   • theme: %s%b\n' "$GRAY" "$THEME" "$RESET"
    IFS= read -rsn1 key
    if [ "$key" = "$ESC" ]; then IFS= read -rsn2 seq; case "$seq" in '[A') key='UP';; '[B') key='DOWN';; esac; fi
    case "$key" in
      UP|k) selected=$((selected-1)); [ "$selected" -lt 0 ] && selected=$((count-1));;
      DOWN|j) selected=$((selected+1)); [ "$selected" -ge "$count" ] && selected=0;;
      '') MENU_RESULT=$selected; return 0;;
      q|Q) MENU_RESULT=-1; return 0;;
    esac
  done
}

multi_menu(){
  local title="$1"; shift
  local -a labels=("$@") marks=()
  local n=${#labels[@]} i selected=0 key seq
  MULTI_RESULT=""
  for ((i=0;i<n;i++)); do marks[$i]=0; done
  while :; do
    header
    printf '%b◆ %s%b\n\n' "$BOLD$ACCENT" "$title" "$RESET"
    for ((i=0;i<n;i++)); do
      local box='○'; [ "${marks[$i]}" -eq 1 ] && box='●'
      if [ "$i" -eq "$selected" ]; then
        printf '  %b▸ %s %-58s%b\n' "$ACCENT$BOLD" "$box" "${labels[$i]}" "$RESET"
      else
        printf '    %s %-58s\n' "$box" "${labels[$i]}"
      fi
    done
    printf '\n%b  Space toggle   a all/none   Enter continue   q back%b\n' "$GRAY" "$RESET"
    IFS= read -rsn1 key
    if [ "$key" = "$ESC" ]; then IFS= read -rsn2 seq; case "$seq" in '[A') key='UP';; '[B') key='DOWN';; esac; fi
    case "$key" in
      UP|k) selected=$((selected-1)); [ "$selected" -lt 0 ] && selected=$((n-1));;
      DOWN|j) selected=$((selected+1)); [ "$selected" -ge "$n" ] && selected=0;;
      ' ') if [ "${marks[$selected]}" -eq 1 ]; then marks[$selected]=0; else marks[$selected]=1; fi;;
      a|A)
        local any=0
        for ((i=0;i<n;i++)); do [ "${marks[$i]}" -eq 0 ] && any=1; done
        for ((i=0;i<n;i++)); do marks[$i]=$any; done;;
      '')
        for ((i=0;i<n;i++)); do [ "${marks[$i]}" -eq 1 ] && MULTI_RESULT="$MULTI_RESULT $i"; done
        MULTI_RESULT="$(trim "$MULTI_RESULT")"; return 0;;
      q|Q) MULTI_RESULT=""; return 1;;
    esac
  done
}

safe_under_home(){ case "$1" in "$HOME"/*) return 0;; *) return 1;; esac; }
clear_dir(){
  local p="$1"
  safe_under_home "$p" || { printf '%bRefusing unsafe path: %s%b\n' "$RED" "$p" "$RESET"; return 1; }
  [ -d "$p" ] || return 0
  [ -L "$p" ] && { printf '%bSkipping symlink: %s%b\n' "$YELLOW" "$p" "$RESET"; return 1; }
  find "$p" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
}
trash_path(){
  local src="$1" base dest stamp
  [ -e "$src" ] || return 0
  mkdir -p "$HOME/.Trash"
  base="$(basename "$src")"; dest="$HOME/.Trash/$base"
  if [ -e "$dest" ]; then stamp="$(date +%Y%m%d-%H%M%S)"; dest="$HOME/.Trash/$base-$stamp"; fi
  if mv "$src" "$dest" 2>/dev/null; then return 0; fi
  if [[ "$src" == /Applications/* ]]; then
    osascript - "$src" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  tell application "Finder" to delete POSIX file (item 1 of argv)
end run
APPLESCRIPT
  fi
}

memory_summary(){
  local page free inactive speculative wired compressed active total used
  page="$(vm_stat 2>/dev/null | awk '/page size of/{gsub("[^0-9]","",$8);print $8}')"; [ -n "$page" ] || page=4096
  free="$(vm_stat 2>/dev/null | awk '/Pages free/{gsub("\\.","",$3);print $3+0}')"
  inactive="$(vm_stat 2>/dev/null | awk '/Pages inactive/{gsub("\\.","",$3);print $3+0}')"
  speculative="$(vm_stat 2>/dev/null | awk '/Pages speculative/{gsub("\\.","",$3);print $3+0}')"
  wired="$(vm_stat 2>/dev/null | awk '/Pages wired down/{gsub("\\.","",$4);print $4+0}')"
  compressed="$(vm_stat 2>/dev/null | awk '/Pages occupied by compressor/{gsub("\\.","",$5);print $5+0}')"
  active="$(vm_stat 2>/dev/null | awk '/Pages active/{gsub("\\.","",$3);print $3+0}')"
  total="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  used=$(( (active+wired+compressed) * page ))
  printf '%s / %s' "$(fmt_bytes "$used")" "$(fmt_bytes "$total")"
}

basic_snapshot(){
  SNAP_MODEL="$(sysctl -n hw.model 2>/dev/null || echo Mac)"
  SNAP_OS="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
  SNAP_FREE="$(fmt_bytes "$(free_bytes)")"
  SNAP_MEM="$(memory_summary)"
  SNAP_SWAP="$(sysctl vm.swapusage 2>/dev/null | sed -E 's/.*used = ([0-9.]+[MG]).*/\1/' | head -1)"
  SNAP_UPTIME="$(uptime | sed -E 's/.*up ([^,]+),.*/\1/' | xargs)"
}

status_screen(){
  local key seq
  while :; do
    basic_snapshot
    header
    printf '%b◆ Live Performance%b\n' "$BOLD$ACCENT" "$RESET"
    printf '  %-18s %s\n' 'Model' "$SNAP_MODEL"
    printf '  %-18s %s\n' 'macOS' "$SNAP_OS"
    printf '  %-18s %s\n' 'Free disk' "$SNAP_FREE"
    printf '  %-18s %s\n' 'Memory used' "$SNAP_MEM"
    printf '  %-18s %s\n' 'Swap used' "${SNAP_SWAP:-unknown}"
    printf '  %-18s %s\n' 'Uptime' "$SNAP_UPTIME"
    printf '\n%bTop processes%b\n' "$BOLD" "$RESET"
    ps -Ao pid=,pcpu=,pmem=,comm= -r 2>/dev/null | head -8 | awk '{printf "  %-7s CPU %6s%%  MEM %5s%%  ", $1,$2,$3; $1=$2=$3=""; sub(/^ +/,""); print substr($0,1,36)}'
    printf '\n%bRefreshing every 2s · r refresh · q back%b\n' "$GRAY" "$RESET"
    key=''; IFS= read -rsn1 -t 2 key || true
    [ "$key" = 'q' ] || [ "$key" = 'Q' ] && return 0
  done
}
