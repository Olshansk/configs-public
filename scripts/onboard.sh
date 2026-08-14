#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}
HOST=${HOST:-unknown}
DRY_RUN=${DRY_RUN:-0}
MAKE_BIN=${MAKE_BIN:-make}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

ask() {
  [[ "$DRY_RUN" != 1 && -t 0 ]] || return 1
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

active_profile() {
  profile_read_selector 2>/dev/null || true
}

secrets_file() {
  printf '%s/%s/secrets.sh' \
    "${SECRETS_ROOT:-$HOME/.config/dotfiles/profiles}" "$PROFILE"
}

section() {
  printf '\n%s. %s\n' "$1" "$2"
}

mode_label=interactive
[[ "$DRY_RUN" == 1 ]] && mode_label='read-only dry run'
platform=$(uname -s 2>/dev/null || printf 'unknown')
selected_profile=$(active_profile)

printf 'New machine onboarding\n'
printf 'Profile: %s (%s)\n' "$PROFILE" "$PROFILE_SOURCE"
printf 'Active profile: %s\n' "${selected_profile:-not selected}"
printf 'Host: %s\nPlatform: %s\nMode: %s\n' "$HOST" "$platform" "$mode_label"

printf '\nPreflight\n'
for tool in git zsh jq make; do
  if command -v "$tool" >/dev/null 2>&1; then
    printf '  ready: %s\n' "$tool"
  else
    printf '  missing: %s\n' "$tool"
  fi
done

if [[ "$platform" == Darwin* ]]; then
  if command -v xcode-select >/dev/null 2>&1 && xcode-select -p >/dev/null 2>&1; then
    printf '  ready: Xcode Command Line Tools\n'
  else
    printf '  missing: Xcode Command Line Tools (run xcode-select --install)\n'
  fi
fi

brew_available=0
if command -v brew >/dev/null 2>&1; then
  brew_available=1
  printf '  ready: Homebrew\n'
else
  printf '  missing: Homebrew (https://brew.sh/)\n'
fi

section 1 'Homebrew and applications'
brew_manifest_missing=0
brew_install_deferred=0
if [[ "$brew_available" == 1 ]]; then
  if ! HOMEBREW_NO_AUTO_UPDATE=1 PROFILE="$PROFILE" \
    "$CONFIGS_DIR/scripts/brew.sh" review; then
    brew_manifest_missing=1
  fi
  if [[ "$DRY_RUN" != 1 && "$brew_manifest_missing" == 1 ]]; then
    if ask 'Install missing Homebrew packages and casks?'; then
      PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/brew.sh" install
      brew_manifest_missing=0
    else
      brew_install_deferred=1
    fi
  fi
else
  printf 'Homebrew review skipped until Homebrew is installed.\n'
fi

section 1b 'Application inventory'
app_inventory_missing=0
if ! PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/apps.sh" review; then
  app_inventory_missing=1
fi

section 2 'Managed configuration and active profile'
config_drift=0
if ! PROFILE="$PROFILE" HOST="$HOST" \
  "$CONFIGS_DIR/scripts/config-sync.sh" review; then
  config_drift=1
fi

selected_profile=$(active_profile)
profile_mismatch=0
if [[ "$selected_profile" != "$PROFILE" ]]; then
  profile_mismatch=1
  printf 'Active profile needs selection: %s -> %s\n' \
    "${selected_profile:-not selected}" "$PROFILE"
fi

if [[ "$config_drift" == 1 || "$profile_mismatch" == 1 ]]; then
  if [[ "$DRY_RUN" == 1 ]]; then
    PROFILE="$PROFILE" HOST="$HOST" APPLY=0 DRY_RUN=1 \
      "$CONFIGS_DIR/scripts/config-sync.sh" profile-use
  elif ask "Back up managed configuration, apply it, and activate $PROFILE?"; then
    PROFILE="$PROFILE" HOST="$HOST" APPLY=1 \
      "$CONFIGS_DIR/scripts/config-sync.sh" profile-use
    config_drift=0
  fi
else
  printf 'Managed configuration and active profile are ready.\n'
fi

section 3 'Profile secrets'
secrets_ready=0
if PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/secrets-profile.sh" status; then
  secrets_ready=1
elif [[ ! -f "$(secrets_file)" && "$DRY_RUN" != 1 ]] && \
  ask "Create the blank $PROFILE secrets file?"; then
  PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/secrets-profile.sh" init
  if PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/secrets-profile.sh" status; then
    secrets_ready=1
  fi
fi
printf 'Secret values are never displayed or copied between profiles.\n'

section 4 'History'
"$CONFIGS_DIR/scripts/history-status.sh"
printf 'Onboarding does not copy or synchronize history.\n'
atuin_sync_unsafe=0
hishtory_policy_review=0
if [[ "$PROFILE" == work ]]; then
  atuin_config="${ATUIN_CONFIG:-$HOME/.config/atuin/config.toml}"
  if [[ -f "$atuin_config" ]] && \
    grep -Eq '^[[:space:]]*auto_sync[[:space:]]*=[[:space:]]*true([[:space:]]*(#.*)?)?$' \
      "$atuin_config"; then
    atuin_sync_unsafe=1
    printf 'Work safety warning: Atuin auto_sync is enabled.\n'
  fi
  if command -v hishtory >/dev/null 2>&1; then
    hishtory_policy_review=1
    printf 'Work safety review: Hishtory sends history to its configured service.\n'
  fi
fi

section 5 'Startup items'
PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/startup.sh" review
if [[ "$DRY_RUN" != 1 ]] && ask 'Enable declared login items and LaunchAgents?'; then
  PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/startup.sh" enable
fi

section 6 'Validation'
validation_run=0
if [[ "$DRY_RUN" == 1 ]]; then
  printf 'Validation skipped in dry-run mode.\n'
elif ask 'Run configuration validation now?'; then
  "$MAKE_BIN" -C "$CONFIGS_DIR" PROFILE="$PROFILE" validate
  validation_run=1
else
  printf 'Validation deferred.\n'
fi

selected_profile=$(active_profile)
if PROFILE="$PROFILE" "$CONFIGS_DIR/scripts/secrets-profile.sh" status >/dev/null 2>&1; then
  secrets_ready=1
else
  secrets_ready=0
fi

printf '\nNext actions\n'
if [[ "$brew_available" == 0 ]]; then
  printf '  - Install Homebrew from https://brew.sh/, then rerun onboarding.\n'
elif [[ "$brew_manifest_missing" == 1 || "$brew_install_deferred" == 1 ]]; then
  printf '  - Install any missing manifest items: make PROFILE=%s brew-install\n' "$PROFILE"
fi
if [[ "$app_inventory_missing" == 1 ]]; then
  printf '  - Review managed and manual application follow-up: make PROFILE=%s apps-review\n' "$PROFILE"
fi
if [[ "$selected_profile" != "$PROFILE" || "$config_drift" == 1 ]]; then
  printf '  - Apply and activate the profile: make PROFILE=%s APPLY=1 profile-use\n' "$PROFILE"
fi
if [[ "$secrets_ready" == 0 ]]; then
  if [[ -f "$(secrets_file)" ]]; then
    printf '  - Repair secret-file ownership or permissions: make PROFILE=%s secrets-status\n' "$PROFILE"
  else
    printf '  - Create the profile secrets file: make PROFILE=%s secrets-init\n' "$PROFILE"
  fi
fi
if [[ "$atuin_sync_unsafe" == 1 ]]; then
  printf '  - Set auto_sync = false in %s before entering work commands.\n' "$atuin_config"
fi
if [[ "$hishtory_policy_review" == 1 ]]; then
  printf '  - Confirm Hishtory sync is employer-approved and uses the intended account.\n'
fi
if [[ "$validation_run" == 0 ]]; then
  printf '  - Run validation: make PROFILE=%s validate\n' "$PROFILE"
fi
printf '  - Complete account sign-ins, macOS permissions, and exceptions in apps/manual.md.\n'

printf '\nOnboarding review complete for profile: %s\n' "$PROFILE"
