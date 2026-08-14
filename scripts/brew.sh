#!/usr/bin/env bash
set -euo pipefail

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}
ACTION=${1:-review}
BACKUP_DIR=${BACKUP_DIR:-}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

command -v brew >/dev/null 2>&1 || { printf 'Homebrew is not installed. Install it from https://brew.sh/ first.\n' >&2; exit 1; }
case "$PROFILE" in base|work|personal) ;; *) printf 'Unknown profile: %s\n' "$PROFILE" >&2; exit 2 ;; esac

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
cat "$CONFIGS_DIR/Brewfile.base" "$CONFIGS_DIR/Brewfile.$PROFILE" >"$tmpfile"
review_status=0

case "$ACTION" in
  review|status)
    printf 'Homebrew profile: %s\n' "$PROFILE"
    if brew bundle check --file="$tmpfile"; then
      printf 'All manifest packages are installed.\n'
    else
      printf 'Some manifest packages are missing. Run make PROFILE=%s brew-install.\n' "$PROFILE"
      review_status=1
    fi
    ;;
  install)
    brew bundle --file="$tmpfile"
    printf 'Homebrew installation complete for profile: %s\n' "$PROFILE"
    ;;
  snapshot)
    destination=${BACKUP_DIR:-$HOME/.config-backups/configs/brew}/Brewfile.$PROFILE.$(date +%Y%m%d-%H%M%S)
    mkdir -p "$(dirname "$destination")"
    brew bundle dump --file="$destination" --force
    printf 'Homebrew snapshot written outside the repository: %s\n' "$destination"
    ;;
  *) printf 'Usage: %s {review|install|snapshot|status}\n' "$0" >&2; exit 2 ;;
esac

printf '\nManual application and permission notes:\n'
sed -n '1,200p' "$CONFIGS_DIR/apps/manual.md"

exit "$review_status"
