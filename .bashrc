#!/usr/bin/env bash

# Keep bash portable and do not source zsh-only modules.
_public_configs_dir="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
[[ -r "$_public_configs_dir/.profile" ]] && source "$_public_configs_dir/.profile"
unset _public_configs_dir
