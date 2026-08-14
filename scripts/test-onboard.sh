#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fixture="$TEST_ROOT/configs"
home="$TEST_ROOT/home"
bin="$TEST_ROOT/bin"
log="$TEST_ROOT/actions.log"
mkdir -p "$fixture/scripts" "$fixture/.local" "$home" "$bin"
cp "$REPO_ROOT/scripts/onboard.sh" "$fixture/scripts/onboard.sh"

cat >"$fixture/scripts/profile.sh" <<'EOF'
#!/usr/bin/env bash
PROFILE_STATE_FILE="${PROFILE_STATE_FILE:-$CONFIGS_DIR/.local/active-profile}"
PROFILE_SOURCE=""
profile_read_selector() {
  [[ -f "$PROFILE_STATE_FILE" ]] || return 1
  local selected
  selected=$(<"$PROFILE_STATE_FILE")
  [[ -n "$selected" ]] || return 1
  printf '%s' "$selected"
}
resolve_profile() {
  PROFILE="${1:-}"
  [[ -n "$PROFILE" ]] || PROFILE=$(profile_read_selector)
  PROFILE_SOURCE=explicit
  export PROFILE PROFILE_SOURCE PROFILE_STATE_FILE
}
EOF

cat >"$fixture/scripts/brew.sh" <<'EOF'
#!/usr/bin/env bash
printf 'brew:%s:auto_update=%s\n' "$1" "${HOMEBREW_NO_AUTO_UPDATE:-unset}" >>"$ONBOARD_TEST_LOG"
printf 'Homebrew fixture review\n'
EOF

cat >"$fixture/scripts/apps.sh" <<'EOF'
#!/usr/bin/env bash
printf 'apps:%s\n' "$1" >>"$ONBOARD_TEST_LOG"
printf 'Application inventory fixture status\n'
EOF

cat >"$fixture/scripts/config-sync.sh" <<'EOF'
#!/usr/bin/env bash
printf 'config:%s:apply=%s\n' "$1" "${APPLY:-0}" >>"$ONBOARD_TEST_LOG"
case "$1" in
  review) [[ "${ONBOARD_CONFIG_DRIFT:-0}" == 0 ]] ;;
  profile-use)
    if [[ "${APPLY:-0}" == 1 ]]; then
      printf 'MUTATION:profile-use\n' >>"$ONBOARD_TEST_LOG"
      printf '%s\n' "$PROFILE" >"$CONFIGS_DIR/.local/active-profile"
    fi
    ;;
esac
EOF

cat >"$fixture/scripts/secrets-profile.sh" <<'EOF'
#!/usr/bin/env bash
target="$HOME/.config/dotfiles/profiles/$PROFILE/secrets.sh"
printf 'secrets:%s\n' "$1" >>"$ONBOARD_TEST_LOG"
case "$1" in
  status)
    if [[ -f "$target" ]]; then
      printf 'Status: ready\n'
    else
      printf 'Status: missing\n'
      exit 1
    fi
    ;;
  init)
    printf 'MUTATION:secrets-init\n' >>"$ONBOARD_TEST_LOG"
    mkdir -p "$(dirname "$target")"
    : >"$target"
    ;;
esac
EOF

cat >"$fixture/scripts/history-status.sh" <<'EOF'
#!/usr/bin/env bash
printf 'history:status\n' >>"$ONBOARD_TEST_LOG"
printf 'History fixture status\n'
EOF

cat >"$fixture/scripts/startup.sh" <<'EOF'
#!/usr/bin/env bash
printf 'startup:%s\n' "$1" >>"$ONBOARD_TEST_LOG"
[[ "$1" != enable ]] || printf 'MUTATION:startup-enable\n' >>"$ONBOARD_TEST_LOG"
printf 'Startup fixture review\n'
EOF

cat >"$bin/brew" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF

chmod +x "$fixture/scripts/"*.sh "$bin/brew"

assert_contains() {
  local file="$1"
  local expected="$2"
  rg -F --quiet "$expected" "$file" || {
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  }
}

assert_not_contains() {
  local file="$1"
  local unexpected="$2"
  if rg -F --quiet "$unexpected" "$file"; then
    printf 'Expected %s not to contain: %s\n' "$file" "$unexpected" >&2
    exit 1
  fi
}

# Mismatched profile, missing secrets, and missing Homebrew stay read-only.
mkdir -p "$home/.config/atuin"
printf 'auto_sync = true\n' >"$home/.config/atuin/config.toml"
printf 'personal\n' >"$fixture/.local/active-profile"
: >"$log"
missing_output="$TEST_ROOT/missing.out"
PATH="/usr/bin:/bin" HOME="$home" CONFIGS_DIR="$fixture" PROFILE=work \
  HOST=fixture DRY_RUN=1 ONBOARD_CONFIG_DRIFT=1 ONBOARD_TEST_LOG="$log" \
  "$fixture/scripts/onboard.sh" >"$missing_output" 2>&1

assert_contains "$missing_output" 'Profile: work (explicit)'
assert_contains "$missing_output" 'Active profile: personal'
assert_contains "$missing_output" 'missing: Homebrew'
assert_contains "$missing_output" 'make PROFILE=work APPLY=1 profile-use'
assert_contains "$missing_output" 'make PROFILE=work secrets-init'
assert_contains "$missing_output" 'Work safety warning: Atuin auto_sync is enabled.'
assert_contains "$missing_output" 'Set auto_sync = false'
assert_contains "$log" 'config:profile-use:apply=0'
assert_not_contains "$log" 'MUTATION:'
assert_not_contains "$log" 'secrets:init'
assert_not_contains "$log" 'startup:enable'

# Ready state reports no profile or secret repair action and never leaks values.
mkdir -p "$home/.config/dotfiles/profiles/personal"
secret_marker='ONBOARD_FIXTURE_SECRET_DO_NOT_PRINT'
printf 'export FIXTURE_VALUE=%s\n' "$secret_marker" \
  >"$home/.config/dotfiles/profiles/personal/secrets.sh"
printf 'personal\n' >"$fixture/.local/active-profile"
printf 'auto_sync = false\n' >"$home/.config/atuin/config.toml"
: >"$log"
ready_output="$TEST_ROOT/ready.out"
PATH="$bin:/usr/bin:/bin" HOME="$home" CONFIGS_DIR="$fixture" PROFILE=personal \
  HOST=fixture DRY_RUN=1 ONBOARD_CONFIG_DRIFT=0 ONBOARD_TEST_LOG="$log" \
  "$fixture/scripts/onboard.sh" >"$ready_output" 2>&1

assert_contains "$ready_output" 'Managed configuration and active profile are ready.'
assert_contains "$ready_output" 'Status: ready'
assert_contains "$log" 'brew:review:auto_update=1'
assert_not_contains "$ready_output" 'APPLY=1 profile-use'
assert_not_contains "$ready_output" 'secrets-init'
assert_not_contains "$ready_output" 'brew-install'
assert_not_contains "$ready_output" "$secret_marker"
assert_not_contains "$log" 'MUTATION:'

printf '✅ Onboarding dry-run fixtures passed\n'
