#!/bin/zsh

# Portable public shell entrypoint. Secrets and profile state stay outside Git.
_public_configs_dir="${CONFIGS_DIR:-${0:A:h}}"

source "$_public_configs_dir/zshrc.d/core/001.shared_env.sh"
source "$_public_configs_dir/zshrc.d/core/001.env_loader.sh"
source "$_public_configs_dir/zshrc.d/core/002.environment.sh"

for _public_module in \
  "$_public_configs_dir"/zshrc.d/core/{000.keep,005.keys,006.lazy_completions,007.lazy_tools}.sh \
  "$_public_configs_dir"/zshrc.d/development/{001.python,002.ignite,004.postgres,005.node,006.android,007.ffmpeg}.sh \
  "$_public_configs_dir"/zshrc.d/utilities/{001.configs,003.atuin,006.lazy_status}.sh; do
  [[ -r "$_public_module" ]] && source "$_public_module"
done

unset _public_module _public_configs_dir
