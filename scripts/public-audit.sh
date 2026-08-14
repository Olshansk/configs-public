#!/usr/bin/env bash

set -euo pipefail

CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$CONFIGS_DIR"

readonly RED=$'\033[31m'
readonly GREEN=$'\033[32m'
readonly RESET=$'\033[0m'

files=()
while IFS= read -r -d '' file; do
  case "$file" in
    .git/*|.oh-my-zsh/*|scripts/public-audit.sh|scripts/check-secrets.sh|scripts/test-*.sh) continue ;;
  esac
  files+=("$file")
done < <(git ls-files --cached --others --exclude-standard -z)

patterns=(
  '/Users/[A-Za-z0-9._/-]+'
  '/home/[A-Za-z0-9._/-]+'
  'boredmlogs|corp\.google|market-navigator|pokt-network|olshansk\.info'
  'sk-(ant-|or-v1-)?[A-Za-z0-9_-]{16,}'
  'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
  'AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}'
  '-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----'
  '[A-Za-z][A-Za-z0-9+.-]*://[^$[:space:]/:@]+:[^$[:space:]@]+@'
  "(PASSWORD|PASSPHRASE|TOKEN|SECRET|API[_-]?KEY|PRIVATE[_ -]?KEY)[[:space:]]*[:=][[:space:]]*[\"']?[^$\"'{}[:space:]]{12,}"
  '0x[0-9a-fA-F]{40}'
)

failures=0
for pattern in "${patterns[@]}"; do
  matches="$(rg -l -I -i -e "$pattern" "${files[@]}" 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    printf '%s❌ Potential public-data match in:%s\n%s\n' "$RED" "$RESET" "$matches"
    failures=1
  fi
done

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  if git fsck --full --no-reflogs --unreachable 2>/dev/null | rg -q .; then
    printf '%s❌ Unreachable Git objects exist; public history is not clean%s\n' "$RED" "$RESET"
    failures=1
  fi
else
  printf '%s⚠️ No public commit exists yet; rerun this audit after the initial root commit%s\n' "$RED" "$RESET"
fi

if [[ "$failures" == 1 ]]; then
  printf '%sPublic audit failed. Review matches without printing secret values.%s\n' "$RED" "$RESET"
  exit 1
fi

printf '%s✅ Public tree and history passed the privacy audit%s\n' "$GREEN" "$RESET"
