#!/bin/bash
# Lazy Loading for Shell Completions
# Only loads completions when the command is first used - SAFE VERSION

# Safety check - skip if lazy loading is disabled
[[ "$DISABLE_LAZY_LOADING" == "1" ]] && return 0

# Track loaded completions
typeset -A _completion_loaded

# Store original command paths to avoid recursion
typeset -A _original_commands

# Initialize original command paths
_init_original_commands() {
    local tools=("docker" "gcloud" "gh" "pip" "poetry" "npm")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            _original_commands[$tool]=$(command -v "$tool")
        fi
    done
}

# Function to set up lazy loading for a command - RECURSION-SAFE
lazy_completion() {
    local cmd="$1"
    local completion_loader="$2"

    # Store original command path
    _original_commands[$cmd]=$(command -v "$cmd" 2>/dev/null)

    # Create a wrapper function that loads completion on first use
    eval "${cmd}() {
        # Load completion only once
        if [[ -z \"\$_completion_loaded[$cmd]\" ]]; then
            _completion_loaded[$cmd]=1

            # Load completion using the original command path to avoid recursion
            local original_cmd=\"\$_original_commands[$cmd]\"
            if [[ -n \"\$original_cmd\" ]]; then
                eval \"${completion_loader}\" 2>/dev/null || true
            fi
        fi

        # Remove this wrapper function
        unfunction ${cmd} 2>/dev/null

        # Call the original command
        local original_cmd=\"\$_original_commands[$cmd]\"
        if [[ -n \"\$original_cmd\" ]]; then
            \"\$original_cmd\" \"\$@\"
        else
            command ${cmd} \"\$@\"
        fi
    }"
}

# Initialize command paths
_init_original_commands

# kubectl completion is loaded immediately in cloud/003.kubectl.sh
# This prevents lazy loading to ensure kubectl is always ready

# Lazy load docker completion - SAFE VERSION
if [[ -n "${_original_commands[docker]}" ]]; then
    lazy_completion docker "
        if [[ -f /Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion ]]; then
            source /Applications/Docker.app/Contents/Resources/etc/docker.zsh-completion
        elif [[ -f /usr/local/share/zsh/site-functions/_docker ]]; then
            autoload -U _docker
        fi
    "
fi

# Lazy load gcloud completion - SAFE VERSION
if [[ -n "${_original_commands[gcloud]}" ]]; then
    lazy_completion gcloud "
        if [[ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]]; then
            source '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'
        elif [[ -f '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc' ]]; then
            source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'
        fi
    "
fi

# Lazy load gh (GitHub CLI) completion - SAFE VERSION
if [[ -n "${_original_commands[gh]}" ]]; then
    lazy_completion gh "\"\$_original_commands[gh]\" completion -s zsh | source /dev/stdin"
fi

# For pip, poetry, npm - these are less likely to cause recursion but still make safe
if [[ -n "${_original_commands[pip]}" ]]; then
    lazy_completion pip "\"\$_original_commands[pip]\" completion --zsh | source /dev/stdin"
fi

if [[ -n "${_original_commands[npm]}" ]]; then
    lazy_completion npm "\"\$_original_commands[npm]\" completion | source /dev/stdin"
fi

# Poetry is tricky - disable lazy loading for now to avoid issues
# if [[ -n "${_original_commands[poetry]}" ]]; then
#     lazy_completion poetry "poetry completions zsh > ~/.zfunc/_poetry && fpath+=~/.zfunc"
# fi