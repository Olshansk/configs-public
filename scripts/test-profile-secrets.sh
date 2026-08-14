#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

home="$TEST_ROOT/home"
secrets_root="$home/.config/dotfiles/profiles"
mkdir -p "$secrets_root/personal" "$secrets_root/work"
chmod 700 "$home/.config" "$home/.config/dotfiles" "$secrets_root" \
  "$secrets_root/personal" "$secrets_root/work"

printf 'export PROFILE_MARKER="personal"\n' >"$secrets_root/personal/secrets.sh"
printf 'export PROFILE_MARKER="work"\n' >"$secrets_root/work/secrets.sh"
chmod 600 "$secrets_root/personal/secrets.sh" "$secrets_root/work/secrets.sh"

HOME="$home" DOTFILES_PROFILE=work zsh -f -c \
  'source "$1" 2>/dev/null; [[ "$PROFILE_MARKER" == work ]]' \
  _ "$REPO_ROOT/zshrc.d/core/001.env_loader.sh"

HOME="$home" DOTFILES_PROFILE=personal zsh -f -c \
  'source "$1" 2>/dev/null; [[ "$PROFILE_MARKER" == personal ]]' \
  _ "$REPO_ROOT/zshrc.d/core/001.env_loader.sh"

chmod 644 "$secrets_root/work/secrets.sh"
HOME="$home" DOTFILES_PROFILE=work zsh -f -c \
  'source "$1" 2>/dev/null; [[ -z "${PROFILE_MARKER:-}" ]]' \
  _ "$REPO_ROOT/zshrc.d/core/001.env_loader.sh"

generated_root="$TEST_ROOT/generated"
HOME="$home" CONFIGS_DIR="$REPO_ROOT" PROFILE=work SECRETS_ROOT="$generated_root" \
  "$REPO_ROOT/scripts/secrets-profile.sh" init >/dev/null
mode="$(stat -f '%Lp' "$generated_root/work/secrets.sh" 2>/dev/null || stat -c '%a' "$generated_root/work/secrets.sh")"
[[ "$mode" == 600 ]] || { printf 'Generated secrets mode was %s, expected 600\n' "$mode" >&2; exit 1; }

printf '✅ Profile secret isolation fixtures passed\n'
