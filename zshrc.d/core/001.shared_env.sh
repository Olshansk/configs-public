# Shared shell environment exports.
# Keep this file POSIX-ish so zsh, bash, and login shells can source it.

if [ "${_PUBLIC_SHARED_ENV_LOADED:-0}" = 1 ]; then
  return 0
fi
_PUBLIC_SHARED_ENV_LOADED=1

path_prepend() {
  case ":${PATH:-}:" in
    *":$1:"*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  case ":${PATH:-}:" in
    *":$1:"*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

path_append "$HOME/.hishtory"
path_prepend "$HOME/.rd/bin"
path_append "$HOME/.lmstudio/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.local/share/solana/install/active_release/bin"

export PATH
