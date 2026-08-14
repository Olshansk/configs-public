#!/usr/bin/env bash
set -u

printf 'Shell history\n'
printf '  HISTFILE=%s\n' "${HISTFILE:-<unset>}"
printf '  HISTSIZE=%s SAVEHIST=%s\n' "${HISTSIZE:-<unset>}" "${SAVEHIST:-<unset>}"
for path in "$HOME/.zsh_history" "$HOME/.bash_history" "$HOME/.zsh_history_ext"; do
  if [[ -e "$path" || -L "$path" ]]; then
    printf '  %s (%s)\n' "$path" "$(du -h "$path" 2>/dev/null | awk '{print $1}' || printf 'unreadable')"
  else
    printf '  %s (missing)\n' "$path"
  fi
done

printf '\nAtuin\n'
if command -v atuin >/dev/null 2>&1; then
  printf '  installed: %s\n' "$(atuin --version 2>/dev/null || printf 'yes')"
  config="$HOME/.config/atuin/config.toml"
  if [[ -f "$config" ]]; then
    rg '^(auto_sync|sync_address|sync_frequency|secrets_filter)\s*=' "$config" | sed 's/^/  /' || true
  else
    printf '  config: missing\n'
  fi
  [[ -f "$HOME/.local/share/atuin/history.db" ]] && printf '  local database: %s\n' "$(du -h "$HOME/.local/share/atuin/history.db" | awk '{print $1}')"
else
  printf '  installed: no\n'
fi

printf '\nHishtory\n'
if command -v hishtory >/dev/null 2>&1; then
  printf '  installed: yes\n  Ctrl-R: Hishtory\n'
  hishtory config-get enable-control-r 2>/dev/null | sed 's/^/  control-r enabled: /' || true
  hishtory status 2>/dev/null | sed -E 's/(Secret Key:).*/\1 [redacted]/' | sed 's/^/  /' || true
else
  printf '  installed: no\n'
fi

printf '\nHotkeys\n  Ctrl-R: Hishtory\n  Ctrl-N: Atuin\n'
printf '  Both tools capture shell commands; Atuin should remain auto_sync=false for local-only work history.\n'
