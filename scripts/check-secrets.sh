#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$CONFIGS_DIR"

readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly RESET=$'\033[0m'

tracked_files=()
while IFS= read -r file; do
  case "$file" in
    .oh-my-zsh/*|claude/plugins/marketplaces/*) continue ;;
  esac
  [[ -f "$file" ]] && tracked_files+=("$file")
done < <(
  git -C "$CONFIGS_DIR" ls-files --cached --others --exclude-standard -- \
    '*.sh' '*.zsh' '*.bash' '*.env' '*.toml' '*.json' '*.yaml' '*.yml' '*.plist'
)

if [[ ${#tracked_files[@]} -eq 0 ]]; then
  printf '%s✅ No tracked shell files to scan%s\n' "$GREEN" "$RESET"
  exit 0
fi

matches=()

collect_matches() {
  local pattern="$1"
  local match=""
  local file=""
  local line=""
  local remainder=""
  while IFS= read -r match; do
    IFS=: read -r file line remainder <<<"$match"
    matches+=("$file:$line:[value redacted]")
  done < <(
    rg -n -i --no-heading -e "$pattern" "${tracked_files[@]}" 2>/dev/null || true
  )
}

collect_matches_case_sensitive() {
  local pattern="$1"
  local match=""
  local file=""
  local line=""
  local remainder=""
  while IFS= read -r match; do
    IFS=: read -r file line remainder <<<"$match"
    matches+=("$file:$line:[value redacted]")
  done < <(
    rg -n --no-heading -e "$pattern" "${tracked_files[@]}" 2>/dev/null || true
  )
}

# Sensitive shell and structured-config assignments must be empty or variable-backed.
collect_matches "(^|[[:space:]{,])(export[[:space:]]+)?[\"']?[A-Z0-9_-]*(PASSWORD|PASSPHRASE|PASS|TOKEN|SECRET|SECRET_KEY|CLIENT_SECRET|ACCESS_KEY|API_KEY|PRIVATE_KEY)[\"']?[[:space:]]*[:=][[:space:]]*([\"'][^\$\"'{}[:space:]][^\"']*[\"']|[^\$\"'{}[:space:]][^,[:space:]]*)"

# Credentials embedded in connection URLs are never allowed in tracked files.
collect_matches '[A-Za-z][A-Za-z0-9+.-]*://[^$[:space:]/:@]+:[^$[:space:]@]+@'

# Common high-confidence credential prefixes.
collect_matches_case_sensitive '(sk-(ant-|or-v1-)?[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----)'

if [[ ${#matches[@]} -gt 0 ]]; then
  printf '%s❌ Potential secrets found in tracked or unignored files:%s\n' "$RED" "$RESET"
  printf '%s\n' "${matches[@]}" | sort -u | sed 's/^/  /'
  exit 1
fi

check_private_file() {
  local file="$1"
  local mode=""
  [[ -f "$file" ]] || return 0
  mode="$(stat -f '%Lp' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)"
  if [[ ! -O "$file" || ( "$mode" != 600 && "$mode" != 400 ) ]]; then
    printf '%s❌ Insecure secret file permissions: %s (mode %s; expected current owner and 600 or 400)%s\n' \
      "$RED" "$file" "$mode" "$RESET"
    return 1
  fi
}

if [[ "${CHECK_LOCAL_SECRETS:-1}" == 1 ]]; then
  local_secret_error=0
  for profile in personal work; do
    check_private_file "$HOME/.config/dotfiles/profiles/$profile/secrets.sh" || local_secret_error=1
    check_private_file "$CONFIGS_DIR/.local/profiles/$profile/secrets.sh" || local_secret_error=1
  done
  [[ "$local_secret_error" == 0 ]] || exit 1
fi

printf '%s✅ No secret literals found; local profile secret permissions are safe%s\n' "$GREEN" "$RESET"
