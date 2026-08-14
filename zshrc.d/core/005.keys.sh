# Authentication helpers. Credentials are loaded by core/001.env_loader.sh.

# SSH key management functions
load_ssh_keys() {
    local ssh_dir="$HOME/.ssh"

    if [[ -d "$ssh_dir" ]]; then
        # Load common SSH keys if they exist
        for key in id_rsa id_ed25519 id_ecdsa; do
            if [[ -f "$ssh_dir/$key" ]]; then
                ssh-add -K "$ssh_dir/$key" 2>/dev/null
            fi
        done
    fi
}

# Git credential helper setup
setup_git_credentials() {
    # Use macOS keychain for Git credentials
    git config --global credential.helper osxkeychain
}

# Lazy initialize key loading (only when ssh/git commands are used)
lazy_load_ssh_keys() {
    if [[ -z "$SSH_KEYS_LOADED" ]]; then
        export SSH_KEYS_LOADED=1
        load_ssh_keys
        setup_git_credentials
    fi
}

# Override ssh command to lazy load keys
ssh() {
    lazy_load_ssh_keys
    unfunction ssh
    command ssh "$@"
}

# Git credentials will be loaded by the git wrapper in 000.keep.sh
# SSH keys loaded on ssh command use only
