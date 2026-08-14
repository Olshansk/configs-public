#!/bin/zsh

# Node version manager: fnm (Rust, ~5ms init).
# Replaces nvm; the portable shell configuration keeps this module optional.
# the (now-removed) lazy nvm wrapper. ~/.nvm is kept on disk as a fallback
# but no longer sourced.
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

# TODO_REMOVE_LATER: keep NVM_DIR exported until ~/.nvm is fully retired.
# Some legacy scripts and IDE integrations still read $NVM_DIR.
export NVM_DIR="$HOME/.nvm"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
