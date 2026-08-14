#!/usr/bin/env bash
# Sets Antigravity IDE as the default macOS app for common code/config file extensions.
# Persisted in macOS Launch Services — re-run this after a wipe or new machine.
# https://github.com/ghostty-org/ghostty/discussions/4379 (when Ghostty link= lands, also uncomment ghostty config)

set -euo pipefail

BUNDLE_ID="com.google.antigravity-ide"

extensions=(
  # Source code
  py js ts tsx jsx mjs cjs
  go rs rb java c cpp h hpp cs swift kt php m lua r scala clj ex exs dart
  vue svelte

  # Config / data
  json yaml yml toml xml env ini cfg conf plist

  # Shell
  sh zsh bash fish

  # Docs
  md txt rst

  # Web
  css scss sass less graphql gql

  # Database
  sql

  # Build / package
  lock gradle pom sbt
)

success=0
failed=0

# Resolve UTI per extension and bind by UTI.
# Binding by extension alone fails to override when multiple apps claim the same UTI.
# Hardcoded overrides for extensions whose mdls-resolved UTI is wrong or ambiguous
# (e.g. .ts → public.mpeg-2-transport-stream, .go → dyn UTI that LS ignores).
declare -A UTI_OVERRIDE=(
  [ts]=com.microsoft.typescript
  [tsx]=com.microsoft.typescript
  [go]=public.go-source
)

ext_to_uti() {
  local ext="$1"
  if [[ -n "${UTI_OVERRIDE[$ext]:-}" ]]; then
    echo "${UTI_OVERRIDE[$ext]}"
    return 0
  fi
  local tmp
  tmp="$(mktemp -t "duti.XXXXXX").${ext}"
  : > "$tmp"
  local uti
  uti="$(mdls -name kMDItemContentType -raw "$tmp" 2>/dev/null)"
  rm -f "$tmp"
  if [[ -z "$uti" || "$uti" == "(null)" ]]; then
    return 1
  fi
  echo "$uti"
}

for ext in "${extensions[@]}"; do
  uti="$(ext_to_uti "$ext")" || uti=""
  if [[ -n "$uti" ]] && duti -s "$BUNDLE_ID" "$uti" all 2>/dev/null; then
    echo "✅ $ext ($uti)"
    success=$((success + 1))
  else
    echo "❌ $ext"
    failed=$((failed + 1))
  fi
done

echo ""
echo "Done: $success succeeded, $failed failed"
