#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

git -C "$TEST_ROOT" init -q
git -C "$TEST_ROOT" config user.name "Validation Test"
git -C "$TEST_ROOT" config user.email "validation-test@example.invalid"

printf 'export %s%s="$%s%s"\n' OPENAI_ API_KEY OPENAI_ API_KEY >"$TEST_ROOT/env-backed.sh"
git -C "$TEST_ROOT" add env-backed.sh
git -C "$TEST_ROOT" commit -qm "test: initialize validation fixture"

CHECK_LOCAL_SECRETS=0 CONFIGS_DIR="$TEST_ROOT" "$REPO_ROOT/scripts/check-secrets.sh" >/dev/null

printf 'export %s%s="literal-test-value"\n' OPENAI_ API_KEY >"$TEST_ROOT/untracked.sh"
if CHECK_LOCAL_SECRETS=0 CONFIGS_DIR="$TEST_ROOT" "$REPO_ROOT/scripts/check-secrets.sh" >/dev/null 2>&1; then
    printf 'Expected untracked literal secret to fail validation\n' >&2
    exit 1
fi
rm -f "$TEST_ROOT/untracked.sh"

printf 'secrets.sh\n' >"$TEST_ROOT/.gitignore"
printf 'export %s%s="ignored-test-value"\n' OPENAI_ API_KEY >"$TEST_ROOT/secrets.sh"
CHECK_LOCAL_SECRETS=0 CONFIGS_DIR="$TEST_ROOT" "$REPO_ROOT/scripts/check-secrets.sh" >/dev/null

printf '{"api_%s":"structured-test-value"}\n' token >"$TEST_ROOT/untracked.json"
output="$(CHECK_LOCAL_SECRETS=0 CONFIGS_DIR="$TEST_ROOT" "$REPO_ROOT/scripts/check-secrets.sh" 2>&1 || true)"
if [[ "$output" != *"untracked.json:1:[value redacted]"* ]]; then
    printf 'Expected structured secret to be detected with redacted output\n' >&2
    exit 1
fi
if [[ "$output" == *"structured-test-value"* ]]; then
    printf 'Secret scanner leaked a detected value\n' >&2
    exit 1
fi

printf '✅ Configuration validation fixtures passed\n'
