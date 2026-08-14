#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROFILE_INPUT="${PROFILE:-}"
ACTION="${1:-status}"
SECRETS_ROOT="${SECRETS_ROOT:-$HOME/.config/dotfiles/profiles}"

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

template="$CONFIGS_DIR/profiles/$PROFILE/secrets_template.sh"
target="$SECRETS_ROOT/$PROFILE/secrets.sh"

file_mode() {
  stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null
}

status() {
  printf 'Profile: %s\nSecrets file: %s\n' "$PROFILE" "$target"
  if [[ ! -f "$target" ]]; then
    printf 'Status: missing\n'
    return 1
  fi

  mode="$(file_mode "$target")"
  if [[ ! -O "$target" || ( "$mode" != 600 && "$mode" != 400 ) ]]; then
    printf 'Status: insecure ownership or mode (%s); expected current owner and 600 or 400\n' "$mode" >&2
    return 1
  fi

  printf 'Status: ready (mode %s)\n' "$mode"
}

init() {
  [[ -f "$template" ]] || { printf 'Missing template: %s\n' "$template" >&2; return 1; }
  [[ ! -e "$target" ]] || { printf 'Refusing to overwrite existing secrets file: %s\n' "$target" >&2; return 1; }

  mkdir -p "$(dirname "$target")"
  chmod 700 "$SECRETS_ROOT" "$(dirname "$target")"
  install -m 600 "$template" "$target"
  printf 'Created profile secrets file: %s\n' "$target"
  printf 'Fill it from your password manager; do not copy credentials across profiles.\n'
}

case "$ACTION" in
  init) init ;;
  status) status ;;
  *) printf 'Usage: %s {init|status}\n' "$0" >&2; exit 2 ;;
esac
