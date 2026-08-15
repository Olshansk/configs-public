#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

git -C "$TEST_ROOT" init -q
git -C "$TEST_ROOT" config user.name "Public Audit Test"
git -C "$TEST_ROOT" config user.email "public-audit@example.invalid"
mkdir -p "$TEST_ROOT/scripts"
cp "$REPO_ROOT/scripts/public-audit.sh" "$TEST_ROOT/scripts/public-audit.sh"
chmod +x "$TEST_ROOT/scripts/public-audit.sh"
printf 'safe\n' >"$TEST_ROOT/safe.txt"
printf 'local-only\n' | git -C "$TEST_ROOT" hash-object -w --stdin >/dev/null

if (cd "$TEST_ROOT" && ./scripts/public-audit.sh) >/dev/null 2>&1; then
  :
else
  printf 'Expected safe fixture to pass public audit\n' >&2
  exit 1
fi

printf 'OPENAI_%s="sk-%s"\n' API_KEY test-public-audit-value >"$TEST_ROOT/unsafe.txt"
if (cd "$TEST_ROOT" && ./scripts/public-audit.sh) >/dev/null 2>&1; then
  printf 'Expected credential fixture to fail public audit\n' >&2
  exit 1
fi

printf '✅ Public audit fixtures passed\n'
