#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fixture="$TEST_ROOT/configs"
home="$TEST_ROOT/home"
backup="$TEST_ROOT/backup"
mkdir -p "$fixture/scripts" "$fixture/profiles/personal/macos/shared/ghostty" \
  "$fixture/profiles/work/macos/shared/ghostty" "$home"
cp "$REPO_ROOT/scripts/config-sync.sh" "$REPO_ROOT/scripts/profile.sh" "$fixture/scripts/"
cat >"$fixture/config-manifest.sh" <<'EOF'
#!/usr/bin/env bash

CONFIG_MANIFEST=(
  "ghostty|link|all|$CONFIGS_DIR/profiles/$PROFILE/macos/shared/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  "personal-only|copy|personal|$CONFIGS_DIR/personal-only|$HOME/.personal-only"
)
EOF
printf 'personal\n' >"$fixture/profiles/personal/macos/shared/ghostty/config"
printf 'work\n' >"$fixture/profiles/work/macos/shared/ghostty/config"
printf 'personal\n' >"$fixture/personal-only"

if env -u PROFILE CONFIGS_DIR="$fixture" HOME="$home" TOOLS=ghostty \
  "$fixture/scripts/config-sync.sh" status >/dev/null 2>&1; then
  printf 'Expected missing active profile to fail\n' >&2
  exit 1
fi

CONFIGS_DIR="$fixture" HOME="$home" PROFILE=work TOOLS=ghostty \
  "$fixture/scripts/config-sync.sh" profile-use >/dev/null
[[ ! -e "$fixture/.local/active-profile" ]] || {
  printf 'Dry-run unexpectedly wrote the active profile selector\n' >&2
  exit 1
}

mkdir -p "$home/Library/Application Support/com.mitchellh.ghostty"
ln -s "$fixture/profiles/personal/macos/shared/ghostty/config" \
  "$home/Library/Application Support/com.mitchellh.ghostty/config"
mkdir -p "$fixture/.local"
printf 'personal\n' >"$fixture/.local/active-profile"
CONFIGS_DIR="$fixture" HOME="$home" PROFILE=work APPLY=1 TOOLS=all BACKUP_DIR="$backup" \
  "$fixture/scripts/config-sync.sh" profile-use >/dev/null

[[ "$(<"$fixture/.local/active-profile")" == work ]] || {
  printf 'Profile switch did not persist work selector\n' >&2
  exit 1
}
[[ "$(readlink "$home/Library/Application Support/com.mitchellh.ghostty/config")" == \
  "$fixture/profiles/work/macos/shared/ghostty/config" ]] || {
  printf 'Profile switch did not relink Ghostty\n' >&2
  exit 1
}
[[ -L "$backup/home/Library/Application Support/com.mitchellh.ghostty/config" ]] || {
  printf 'Profile switch did not back up the existing Ghostty link\n' >&2
  exit 1
}
[[ ! -e "$home/.personal-only" ]] || {
  printf 'Work profile unexpectedly installed a personal-only entry\n' >&2
  exit 1
}

printf 'bogus\n' >"$fixture/.local/active-profile"
if env -u PROFILE CONFIGS_DIR="$fixture" HOME="$home" TOOLS=ghostty \
  "$fixture/scripts/config-sync.sh" status >/dev/null 2>&1; then
  printf 'Expected invalid active profile to fail\n' >&2
  exit 1
fi

printf '✅ Profile management fixtures passed\n'
