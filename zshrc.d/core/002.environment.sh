#!/bin/bash

# Optimized Oh My Zsh Configuration - Fast but Functional
UNAME=$(uname | tr "[:upper:]" "[:lower:]")

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agnoster"

# OPTIMIZED: Essential plugins only - others loaded on demand
plugins=(
  git                      # Essential for gst and git aliases
  zsh-syntax-highlighting  # Essential for syntax colors
  zsh-autosuggestions     # Essential for shadow autocomplete
  dotenv
)

# Performance optimizations for Oh My Zsh
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true
COMPLETION_WAITING_DOTS=false

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Essential PATH exports (needed immediately)
export PATH="$PATH:$HOME/.cargo/bin"

# Go environment (lightweight - always load)
if [[ -d "/opt/homebrew/opt/go@1.23/bin" ]]; then
    export PATH="/opt/homebrew/opt/go@1.23/bin:$PATH"
fi
if command -v go >/dev/null 2>&1; then
    export GOPATH=$(go env GOPATH)
    export PATH="$PATH:$GOPATH/bin"
fi

# Configure autosuggestions for better UX
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"  # Gray suggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # Use both history and completion

# OPTIMIZED: Lazy load heavy plugins only when needed
load_ruby_plugins() {
    if [[ -z "$RUBY_PLUGINS_LOADED" ]]; then
        export RUBY_PLUGINS_LOADED=1

        # Load Ruby-specific plugins
        local ruby_plugins=(bundler rake rbenv ruby)
        for plugin in "${ruby_plugins[@]}"; do
            if [[ -f "$ZSH/plugins/$plugin/$plugin.plugin.zsh" ]]; then
                source "$ZSH/plugins/$plugin/$plugin.plugin.zsh"
            fi
        done
    fi
}

# Autosuggestions are now loaded directly in plugins array above

# Auto-load Ruby plugins only in Ruby projects
if [[ -f "Gemfile" || -f "Rakefile" || -f ".ruby-version" ]]; then
    load_ruby_plugins
fi

# OPTIMIZED: Minimal completion setup
fpath+=~/.zfunc
autoload -U compinit
# Only rebuild completions if needed (much faster)
# Check if .zcompdump is older than 24 hours
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Skip security check for speed
fi

# OPTIMIZED: Conditional loading of heavy features
load_heavy_features() {
    # Only load if not already loaded
    [[ -n "$HEAVY_FEATURES_LOADED" ]] && return
    export HEAVY_FEATURES_LOADED=1

    # Enable bash completions (only if needed)
    autoload -U bashcompinit
    bashcompinit

    # Environment variables
    export PKG_CONFIG_PATH="/usr/local/opt/readline/lib/pkgconfig"
    export PATH="/usr/local/opt/python/libexec/bin:$PATH"
    export PATH="$PATH:$HOME/.local/bin"

    # Tool initialization moved to lazy loading system
    # pyenv, nvm, rbenv, etc. now load on first use via 007.lazy_tools.sh

    # Other lightweight exports
    export PYTHONSTARTUP="$HOME/.pythonstartup"
    export EDITOR=windsurf
}

# OPTIMIZED: Powerline setup (only if powerline-shell exists)
setup_powerline() {
    if command -v powerline-shell >/dev/null 2>&1; then
        function powerline_precmd() {
            PS1="$(powerline-shell --shell zsh $?)"
        }

        function install_powerline_precmd() {
            add-zsh-hook precmd powerline_precmd
        }

        install_powerline_precmd
    fi
}

# OPTIMIZED: Essential aliases only
alias reload="source ~/.zshrc"
alias gamend='git commit -a --amend --no-edit'
alias gl="git log --graph -10 --format='%C(yellow)%h%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias ws="windsurf"
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias ag="/Applications/Antigravity\ IDE.app/Contents/Resources/app/bin/antigravity-ide"

# OPTIMIZED: Essential functions only
function htail() {
    history | tail -n ${1:-10} | awk '{$1=""; sub(/^ +/, ""); print}'
}

function hgrep() {
    history | grep $1
}

# OPTIMIZED: Zsh history (lightweight settings)
export HISTSIZE=50000
export SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups
setopt hist_ignore_space

# OPTIMIZED: Load heavy features in background or on-demand
if [[ "$ZSHRC_LOAD_HEAVY" == "1" ]] || [[ "$FORCE_LOAD_ALL" == "1" ]]; then
    load_heavy_features
else
    # Disable job monitoring temporarily for silent background loading
    setopt no_monitor 2>/dev/null || true

    # Note: Background loading doesn't work for environment variables
    # because subshells can't modify the parent shell's environment.
    # Consider using the load-heavy alias to manually load these features
    # when needed, or set ZSHRC_LOAD_HEAVY=1 for automatic loading.

    # Re-enable job monitoring
    setopt monitor 2>/dev/null || true
fi

# Load powerline
setup_powerline

# iTerm integration (kept for existing terminal support)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# OPTIMIZED: gdircolors only if available
command -v gdircolors >/dev/null 2>&1 && eval "$(gdircolors)"

# Auto-source .env files
# eval "$(direnv hook zsh)"

# eval "$(rbenv init -)"
