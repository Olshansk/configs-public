#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

while IFS=$'\t' read -r method package; do
  case "$method" in
    brew_formula)
      pattern="brew \"$package\""
      ;;
    brew_cask)
      pattern="cask \"$package\""
      ;;
    *)
      continue
      ;;
  esac
  if ! rg -F --quiet "$pattern" "$REPO_ROOT"/Brewfile.base "$REPO_ROOT"/Brewfile.personal "$REPO_ROOT"/Brewfile.work; then
    printf 'Managed package is missing from Brewfiles: %s (%s)\n' "$package" "$method" >&2
    exit 1
  fi
done < <(
  jq -r '
    .tools[]
    | select(.classification == "managed")
    | select(.install.method == "brew_formula" or .install.method == "brew_cask")
    | [.install.method, .install.package]
    | @tsv
  ' "$REPO_ROOT/apps/cli-tools.json"
)

fixture="$TEST_ROOT/configs"
bin="$TEST_ROOT/bin"
mkdir -p "$fixture/scripts" "$fixture/apps" "$bin"
cp "$REPO_ROOT/scripts/apps.sh" "$REPO_ROOT/scripts/profile.sh" "$fixture/scripts/"

cat >"$fixture/apps/cli-tools.json" <<'EOF'
{
  "schema_version": 1,
  "tools": [
    {"command":"formula-ok","classification":"managed","profiles":["personal"],"install":{"method":"brew_formula","package":"formula-ok"}},
    {"command":"cask-ok","classification":"managed","profiles":["personal"],"install":{"method":"brew_cask","package":"cask-ok"}},
    {"command":"brew","classification":"managed","profiles":["personal"],"install":{"method":"bootstrap","package":"homebrew"}},
    {"command":"manual-present","classification":"manual","profiles":["personal"],"install":{"method":"manual","binary":"~/.local/bin/manual-present"}},
    {"command":"manual-missing","classification":"manual","profiles":["personal"],"install":{"method":"manual","binary":"~/.local/bin/manual-missing"}}
  ]
}
EOF

cat >"$bin/brew" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == list ]] || exit 2
case "$3" in
  formula-ok|cask-ok) exit 0 ;;
  *) exit 1 ;;
esac
EOF
cat >"$bin/manual-present" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$bin/brew" "$bin/manual-present"

jq_bin=$(command -v jq)
jq_dir=$(dirname "$jq_bin")
output="$TEST_ROOT/output"
if PATH="$bin:$jq_dir:/usr/bin:/bin" CONFIGS_DIR="$fixture" PROFILE=personal \
  "$fixture/scripts/apps.sh" review >"$output" 2>&1; then
  printf 'Expected missing manual tool to fail review.\n' >&2
  exit 1
fi
rg -F --quiet 'manual tool missing: manual-missing' "$output"

cat >"$bin/manual-missing" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$bin/manual-missing"
PATH="$bin:$jq_dir:/usr/bin:/bin" CONFIGS_DIR="$fixture" PROFILE=personal \
  "$fixture/scripts/apps.sh" review >"$output"
rg -F --quiet 'Application inventory is complete' "$output"

printf '✅ Application inventory fixture tests passed\n'
