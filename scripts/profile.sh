#!/usr/bin/env bash

# Shared profile selection for scripts that operate on machine configuration.

PROFILE_STATE_FILE="${PROFILE_STATE_FILE:-$CONFIGS_DIR/.local/active-profile}"
PROFILE_SOURCE=""

profile_validate() {
  case "${1:-}" in
    personal|work) return 0 ;;
    *)
      printf 'Unknown profile: %s (expected personal or work)\n' "${1:-<empty>}" >&2
      return 2
      ;;
  esac
}

profile_read_selector() {
  [[ -f "$PROFILE_STATE_FILE" ]] || return 1
  local selected
  selected=$(<"$PROFILE_STATE_FILE")
  [[ -n "$selected" ]] || return 1
  printf '%s' "$selected"
}

resolve_profile() {
  local requested="${1:-}"
  if [[ -n "$requested" ]]; then
    PROFILE_SOURCE="explicit"
  else
    if ! requested="$(profile_read_selector)"; then
      printf 'No active profile selected. Create %s or pass PROFILE=personal|work.\n' \
        "$PROFILE_STATE_FILE" >&2
      return 2
    fi
    PROFILE_SOURCE="selector"
  fi
  profile_validate "$requested"
  PROFILE="$requested"
  export PROFILE PROFILE_SOURCE PROFILE_STATE_FILE
}

write_profile_selector() {
  local selected="$1"
  profile_validate "$selected"
  mkdir -p "$(dirname "$PROFILE_STATE_FILE")"
  local temporary
  temporary=$(mktemp "${PROFILE_STATE_FILE}.tmp.XXXXXX")
  trap 'rm -f "$temporary"' RETURN
  printf '%s\n' "$selected" >"$temporary"
  chmod 600 "$temporary"
  mv "$temporary" "$PROFILE_STATE_FILE"
  trap - RETURN
}
