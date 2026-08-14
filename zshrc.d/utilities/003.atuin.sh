# # General: https://github.com/ellie/atuin#shell-plugin
# # Configs: https://atuin.sh/docs/config/key-binding

# # Disabled the defaults (up or ctrl-r)
# eval "$(atuin init zsh --disable-up-arrow --disable-ctrl-r)"
# # eval "$(atuin init zsh --disable-up-arrow)"

# # Enabled a custom (ctrl-T)
# export ATUIN_NOBIND="true"
# # export ATUIN_INLINE_HEIGHT=0
# eval "$(atuin init zsh)"

# bindkey '^N' _atuin_search_widget

# Tell Atuin not to bind any keys automatically
export ATUIN_NOBIND=true

# Initialize Atuin with no default keybindings
eval "$(atuin init zsh)"

# Custom keybindings
bindkey '^N' _atuin_search_widget # Ctrl-N

# Ensure fzf doesn’t override it again
bindkey -r '^R'                   # Remove current binding (fzf-history-widget)
bindkey '^R' _atuin_search_widget # Rebind to Atuin
