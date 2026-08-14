#!/usr/bin/env bash
set -euo pipefail

CONFIGS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/configs/apps"
cp "$CONFIGS_DIR/apps/cli-tools.json" "$tmpdir/configs/apps/cli-tools.json"
marker="$tmpdir/must-not-exist"
cat >"$tmpdir/history" <<EOF
git status && agentsview --version | head
sudo git log
touch $marker
cd /tmp
EOF

report=$(CONFIGS_DIR="$tmpdir/configs" HISTORY_FILE="$tmpdir/history" HISTORY_SOURCE=ext LIMIT=10 QUIET=1 "$CONFIGS_DIR/scripts/cli-discovery.sh")

jq -e '.commands[] | select(.command == "git" and .count == 2)' "$report" >/dev/null
jq -e '.commands[] | select(.command == "agentsview" and .classification == "manual")' "$report" >/dev/null
jq -e '.commands[] | select(.command == "cd" and .classification == "system")' "$report" >/dev/null
[[ ! -e "$marker" ]] || { printf 'History content was executed.\n' >&2; exit 1; }
if jq -e '.. | strings | select(test("must-not-exist"))' "$report" >/dev/null; then
  printf 'Sensitive history content leaked into the report.\n' >&2
  exit 1
fi

printf 'CLI discovery fixture tests passed.\n'
