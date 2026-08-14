#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}
ACTION=${1:-review}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

command -v jq >/dev/null 2>&1 || {
  printf 'jq is required for application inventory review.\n' >&2
  exit 1
}

inventory="$CONFIGS_DIR/apps/cli-tools.json"
[[ -r "$inventory" ]] || {
  printf 'Missing application inventory: %s\n' "$inventory" >&2
  exit 1
}

case "$ACTION" in
  review) ;;
  *)
    printf 'Usage: %s review\n' "$0" >&2
    exit 2
    ;;
esac

missing=0
managed_count=0
manual_count=0
brew_available=0
if command -v brew >/dev/null 2>&1; then
  brew_available=1
else
  printf '  ❌ Homebrew is missing; managed Homebrew tools cannot be checked.\n'
  missing=1
fi

printf 'Application inventory: PROFILE=%s\n' "$PROFILE"

while IFS=$'\t' read -r command_name classification method package notes; do
  case "$classification" in
    managed)
      managed_count=$((managed_count + 1))
      case "$method" in
        brew_formula)
          if [[ "$brew_available" == 1 ]] && brew list --formula "$package" >/dev/null 2>&1; then
            printf '  ✅ managed formula: %s\n' "$package"
          else
            printf '  ❌ missing managed formula: %s (command: %s)\n' "$package" "$command_name"
            missing=1
          fi
          ;;
        brew_cask)
          if [[ "$brew_available" == 1 ]] && brew list --cask "$package" >/dev/null 2>&1; then
            printf '  ✅ managed cask: %s\n' "$package"
          else
            printf '  ❌ missing managed cask: %s (command: %s)\n' "$package" "$command_name"
            missing=1
          fi
          ;;
        bootstrap)
          if command -v "$command_name" >/dev/null 2>&1; then
            printf '  ✅ bootstrap tool: %s\n' "$command_name"
          else
            printf '  ❌ missing bootstrap tool: %s\n' "$command_name"
            missing=1
          fi
          ;;
        *)
          printf '  ⚠️ unsupported managed install method: %s (%s)\n' "$method" "$command_name"
          missing=1
          ;;
      esac
      ;;
    manual)
      manual_count=$((manual_count + 1))
      if command -v "$command_name" >/dev/null 2>&1; then
        printf '  ✅ manual tool present: %s\n' "$command_name"
      else
        printf '  ⚠️ manual tool missing: %s' "$command_name"
        [[ -n "$notes" ]] && printf ' — %s' "$notes"
        printf '\n'
        missing=1
      fi
      ;;
  esac
done < <(
  jq -r --arg profile "$PROFILE" '
    .tools[]
    | select(.profiles | index($profile))
    | [
        .command,
        .classification,
        .install.method,
        (.install.package // ""),
        (.notes // "")
      ]
    | @tsv
  ' "$inventory"
)

printf '\nReviewed %d managed and %d manual tools.\n' "$managed_count" "$manual_count"
if [[ "$missing" == 1 ]]; then
  printf '⚠️ Application inventory has unresolved items. See apps/manual.md for manual follow-up.\n'
  exit 1
fi

printf '✅ Application inventory is complete for PROFILE=%s.\n' "$PROFILE"
