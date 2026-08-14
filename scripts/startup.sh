#!/usr/bin/env bash
set -u

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}
ACTION=${1:-review}
NAME=${NAME:-}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"
UID_VALUE=$(id -u)
items_file="$CONFIGS_DIR/startup/$PROFILE/login-items.txt"
agents_dir="$CONFIGS_DIR/startup/$PROFILE/launch-agents"

item_exists() {
  osascript - "$1" <<'APPLESCRIPT' 2>/dev/null
on run argv
  tell application "System Events" to return exists login item (item 1 of argv)
end run
APPLESCRIPT
}

app_path() {
  mdfind "kMDItemFSName == '$1.app'cd" 2>/dev/null | head -n 1
}

review() {
  printf 'Startup profile: %s\n\nLogin items:\n' "$PROFILE"
  if [[ -f "$items_file" ]]; then
    while IFS= read -r item; do
      [[ -z "$item" || "$item" == \#* ]] && continue
      if item_exists "$item" | grep -q true; then
        printf '  present: %s\n' "$item"
      else
        printf '  missing: %s\n' "$item"
      fi
    done <"$items_file"
  fi
  printf '\nLaunchAgents:\n'
  shopt -s nullglob
  local found=0
  for plist in "$agents_dir"/*.plist; do
    found=1
    label=$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist" 2>/dev/null || basename "$plist" .plist)
    if launchctl print "gui/$UID_VALUE/$label" >/dev/null 2>&1; then
      printf '  loaded: %s\n' "$label"
    else
      printf '  not loaded: %s\n' "$label"
    fi
  done
  [[ "$found" -eq 0 ]] && printf '  none declared\n'
}

enable() {
  [[ -f "$items_file" ]] && while IFS= read -r item; do
    [[ -z "$item" || "$item" == \#* ]] && continue
    path=$(app_path "$item")
    if [[ -z "$path" ]]; then
      printf '⚠️  Cannot enable %s: app not found; install it first.\n' "$item"
      continue
    fi
    if ! item_exists "$item" | grep -q true; then
      osascript - "$item" "$path" <<'APPLESCRIPT'
on run argv
  tell application "System Events"
    make login item at end with properties {name:(item 1 of argv), path:(POSIX file (item 2 of argv)), hidden:false}
  end tell
end run
APPLESCRIPT
    fi
    printf 'enabled login item: %s\n' "$item"
  done <"$items_file"

  shopt -s nullglob
  for plist in "$agents_dir"/*.plist; do
    launchctl bootstrap "gui/$UID_VALUE" "$plist" 2>/dev/null || printf '⚠️  Could not load %s\n' "$plist"
  done
}

disable() {
  [[ -n "$NAME" ]] || { printf 'Pass NAME=... to disable one startup item.\n' >&2; return 2; }
  osascript - "$NAME" <<'APPLESCRIPT'
on run argv
  tell application "System Events"
    if exists login item (item 1 of argv) then delete login item (item 1 of argv)
  end tell
end run
APPLESCRIPT
  launchctl bootout "gui/$UID_VALUE/$NAME" 2>/dev/null || true
  printf 'Disabled startup item or LaunchAgent: %s\n' "$NAME"
}

case "$ACTION" in
  review) review ;;
  enable) enable ;;
  disable) disable ;;
  *) printf 'Usage: %s {review|enable|disable}\n' "$0" >&2; exit 2 ;;
esac
