#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
AGENT_SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/workspace/agent-skills}"
PROFILE_INPUT="${PROFILE:-}"
HOST="${HOST:-$(hostname -s)}"
TOOLS="${TOOLS:-all}"
DRY_RUN="${DRY_RUN:-0}"
BACKUP_DIR="${BACKUP_DIR:-}"
APPLY="${APPLY:-0}"
ACTION="${1:-review}"

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

if [[ -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'
  BLUE=$'\033[34m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
else
  RESET=''
  BLUE=''
  GREEN=''
  YELLOW=''
  RED=''
fi

DRIFT=0
selected_entries=()

source "$CONFIGS_DIR/config-manifest.sh"

print_status() {
  local color="$1"
  local message="$2"
  printf '%b%s%b\n' "$color" "$message" "$RESET"
}

selected() {
  local name="$1"
  local scope="$2"
  [[ "$scope" == "all" || "$scope" == "$PROFILE" ]] || return 1
  [[ "$TOOLS" == "all" || ",$TOOLS," == *",$name,"* ]]
}

manifest_entry() {
  local entry="$1"
  local field="$2"
  local old_ifs="$IFS"
  IFS='|'
  read -r name mode scope source target <<<"$entry"
  IFS="$old_ifs"
  case "$field" in
    name) printf '%s' "$name" ;;
    mode) printf '%s' "$mode" ;;
    scope) printf '%s' "$scope" ;;
    source) printf '%s' "$source" ;;
    target) printf '%s' "$target" ;;
    *) return 1 ;;
  esac
}

select_entries() {
  selected_entries=()
  for entry in "${CONFIG_MANIFEST[@]}"; do
    name="$(manifest_entry "$entry" name)"
    mode="$(manifest_entry "$entry" mode)"
    scope="$(manifest_entry "$entry" scope)"
    source="$(manifest_entry "$entry" source)"
    target="$(manifest_entry "$entry" target)"
    if selected "$name" "$scope"; then
      selected_entries+=("$entry")
    fi
  done
}

select_entries

if [[ ${#selected_entries[@]} -eq 0 ]]; then
  if [[ "$PROFILE" == "work" ]]; then
    print_status "$BLUE" "ℹ️ Requested configuration is personal-only; skipped for PROFILE=work"
    exit 0
  fi
  print_status "$RED" "🚨 No managed entries selected for TOOLS=$TOOLS"
  exit 1
fi

if [[ "$PROFILE" == "work" && "$TOOLS" == "all" ]]; then
  print_status "$BLUE" "ℹ️ Personal AI settings, agent instructions, memories, and iTerm profile are excluded from PROFILE=work"
fi

profile_use() {
  [[ -n "$PROFILE_INPUT" ]] || {
    print_status "$RED" "🚨 profile-use requires PROFILE=personal or PROFILE=work"
    return 2
  }
  profile_validate "$PROFILE"

  if [[ "$APPLY" != "1" ]]; then
    print_status "$BLUE" "🔍 Would switch active profile to $PROFILE"
    print_status "$BLUE" "🔍 Would back up managed targets and apply the $PROFILE profile"
    DRY_RUN=1
    backup
    install_entries
    return 0
  fi

  local requested="$PROFILE"
  print_status "$BLUE" "🔧 Switching active profile to $requested"
  DRY_RUN=0
  local original_profile="$PROFILE"
  PROFILE="personal"
  select_entries
  backup
  PROFILE="$original_profile"
  select_entries
  install_entries
  write_profile_selector "$requested"
  print_status "$GREEN" "✅ Active profile is now $requested"
}

timestamp() {
  date '+%Y%m%d_%H%M%S'
}

backup_root() {
  if [[ -n "$BACKUP_DIR" ]]; then
    printf '%s' "$BACKUP_DIR"
  else
    printf '%s/configs/%s' "$HOME/.config-backups" "$(timestamp)"
  fi
}

safe_target() {
  local target="$1"
  if [[ -d "$target" && ! -L "$target" ]]; then
    print_status "$RED" "🚨 Refusing to replace directory: $target"
    return 1
  fi
}

backup_entry() {
  local name="$1"
  local target="$2"
  local root="$3"
  local relative="${target#$HOME/}"
  local destination="$root/home/$relative"

  [[ -e "$target" || -L "$target" ]] || return 0
  safe_target "$target"
  mkdir -p "$(dirname "$destination")"
  cp -pP "$target" "$destination"
  printf '%s\t%s\n' "$name" "$target" >>"$root/manifest.tsv"
}

backup() {
  local root
  root="$(backup_root)"
  if [[ "$DRY_RUN" == "1" ]]; then
    print_status "$BLUE" "🔍 Would create backup: $root"
    return 0
  fi

  mkdir -p "$root/home"
  chmod 700 "$root"
  printf 'profile=%s\nhost=%s\ntimestamp=%s\n' "$PROFILE" "$HOST" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >"$root/metadata"
  chmod 600 "$root/metadata"
  : >"$root/manifest.tsv"
  chmod 600 "$root/manifest.tsv"

  for entry in "${selected_entries[@]}"; do
    name="$(manifest_entry "$entry" name)"
    mode="$(manifest_entry "$entry" mode)"
    target="$(manifest_entry "$entry" target)"
    case "$mode" in
      link|copy|check)
        backup_entry "$name" "$target" "$root"
        ;;
    esac
  done
  print_status "$GREEN" "✅ Backup created: $root"
}

install_link() {
  local source="$1"
  local target="$2"
  [[ -f "$source" ]] || { print_status "$RED" "🚨 Missing source: $source"; return 1; }
  safe_target "$target"
  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    print_status "$GREEN" "✅ Link unchanged: $target"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    print_status "$BLUE" "🔍 Would link $target → $source"
    return 0
  fi
  [[ -e "$target" || -L "$target" ]] && rm -f "$target"
  ln -s "$source" "$target"
  print_status "$GREEN" "✅ Linked $target → $source"
}

install_copy() {
  local source="$1"
  local target="$2"
  [[ -f "$source" ]] || { print_status "$RED" "🚨 Missing source: $source"; return 1; }
  safe_target "$target"
  mkdir -p "$(dirname "$target")"
  if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
    print_status "$GREEN" "✅ Copy unchanged: $target"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    print_status "$BLUE" "🔍 Would copy $source → $target"
    return 0
  fi
  cp -p "$source" "$target"
  print_status "$GREEN" "✅ Copied $source → $target"
}

install_entries() {
  for entry in "${selected_entries[@]}"; do
    name="$(manifest_entry "$entry" name)"
    mode="$(manifest_entry "$entry" mode)"
    source="$(manifest_entry "$entry" source)"
    target="$(manifest_entry "$entry" target)"
    case "$mode" in
      link) install_link "$source" "$target" ;;
      copy) install_copy "$source" "$target" ;;
      check) print_status "$YELLOW" "⚠️ Manual import remains: $name ($source)" ;;
      agent-link) print_status "$BLUE" "ℹ️ Agent link owned by agent-skills: $name" ;;
      *) print_status "$RED" "🚨 Unknown manifest mode: $mode"; return 1 ;;
    esac
  done
}

review_entry() {
  local name="$1"
  local mode="$2"
  local source="$3"
  local target="$4"

  case "$mode" in
    link|agent-link)
      if [[ ! -e "$source" ]]; then
        print_status "$RED" "❌ $name source missing: $source"
        DRIFT=1
      elif [[ ! -L "$target" ]]; then
        print_status "$YELLOW" "⚠️ $name target is not a symlink: $target"
        DRIFT=1
      elif [[ "$(readlink "$target")" != "$source" ]]; then
        print_status "$YELLOW" "⚠️ $name points elsewhere: $target"
        DRIFT=1
      else
        print_status "$GREEN" "🟢 $name linked"
      fi
      ;;
    copy)
      if [[ ! -f "$source" || ! -f "$target" ]]; then
        print_status "$YELLOW" "⚠️ $name is missing source or target"
        DRIFT=1
      elif diff -q "$source" "$target" >/dev/null; then
        print_status "$GREEN" "🟢 $name matches"
      else
        print_status "$YELLOW" "⚠️ $name differs"
        DRIFT=1
      fi
      ;;
    check)
      if [[ -f "$source" && -e "$target" ]]; then
        print_status "$BLUE" "ℹ️ $name is available for explicit import"
      else
        print_status "$YELLOW" "⚠️ $name source or native target is missing"
        DRIFT=1
      fi
      ;;
    *)
      print_status "$RED" "🚨 Unknown manifest mode: $mode"
      DRIFT=1
      ;;
  esac
}

review() {
  print_status "$BLUE" "🔍 Reviewing PROFILE=$PROFILE HOST=$HOST TOOLS=$TOOLS"
  for entry in "${selected_entries[@]}"; do
    review_entry \
      "$(manifest_entry "$entry" name)" \
      "$(manifest_entry "$entry" mode)" \
      "$(manifest_entry "$entry" source)" \
      "$(manifest_entry "$entry" target)"
  done
  if [[ "$DRIFT" == "1" ]]; then
    print_status "$YELLOW" "⚠️ Review found drift or incomplete integration"
    return 1
  fi
  print_status "$GREEN" "✅ Review is clean"
}

snapshot() {
  local root="$HOME/.config-backups/configs/snapshots/$(timestamp)"
  if [[ "$DRY_RUN" == "1" ]]; then
    print_status "$BLUE" "🔍 Would create snapshot: $root"
    return 0
  fi
  mkdir -p "$root"
  chmod 700 "$root"
  for entry in "${selected_entries[@]}"; do
    mode="$(manifest_entry "$entry" mode)"
    target="$(manifest_entry "$entry" target)"
    name="$(manifest_entry "$entry" name)"
    [[ "$mode" == "link" || "$mode" == "copy" ]] || continue
    [[ -f "$target" ]] || continue
    cp -p "$target" "$root/$name"
  done
  print_status "$GREEN" "✅ Snapshot created: $root"
}

status() {
  printf 'PROFILE=%s\nPROFILE_SOURCE=%s\nPROFILE_STATE_FILE=%s\nHOST=%s\nTOOLS=%s\nCONFIGS_DIR=%s\nAGENT_SKILLS_DIR=%s\n' \
    "$PROFILE" "$PROFILE_SOURCE" "$PROFILE_STATE_FILE" "$HOST" "$TOOLS" "$CONFIGS_DIR" "$AGENT_SKILLS_DIR"
  review || true
}

case "$ACTION" in
  backup) backup ;;
  install) install_entries ;;
  review) review ;;
  setup)
    backup
    install_entries
    ;;
  snapshot) snapshot ;;
  profile-use) profile_use ;;
  status) status ;;
  *)
    printf 'Usage: %s {backup|install|review|setup|snapshot|profile-use|status}\n' "$0" >&2
    exit 2
    ;;
esac
