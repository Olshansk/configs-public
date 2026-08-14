# Git Safety Wrapper - Protects against destructive commands
# Define the top-level directory (TLD) where diffs will be stored; configurable but defaults to /tmp
TLD=${TLD:-"/tmp"}

# Shared hook helper used by shell modules to avoid duplicate registrations.
autoload -Uz add-zsh-hook 2>/dev/null || true

# Git wrapper function to protect against destructive commands
# TEMPORARILY DISABLED - was interfering with Oh My Zsh git aliases
# Uncomment and test after confirming gst works

# git() {
#     # Lazy load SSH keys and git credentials on first git usage
#     if [[ -z "$SSH_KEYS_LOADED" && -n "$SSH_AUTH_SOCK" ]]; then
#         export SSH_KEYS_LOADED=1
#         if command -v ssh-add &>/dev/null; then
#             load_ssh_keys 2>/dev/null
#             setup_git_credentials 2>/dev/null
#         fi
#     fi
#
#     case "$1" in
#         "reset")
#             if [[ "$2" == "--hard" ]]; then
#                 git_safe_reset "$@"
#             else
#                 command git "$@"
#             fi
#             ;;
#         "clean")
#             if [[ "$2" == "-f" || "$2" == "-fd" ]]; then
#                 git_safe_clean "$@"
#             else
#                 command git "$@"
#             fi
#             ;;
#         *)
#             command git "$@"
#             ;;
#     esac
# }

# Safe git reset --hard with backup
git_safe_reset() {
    # Check if we're in a git repository
    if ! command git rev-parse --git-dir &>/dev/null; then
        echo "Not in a git repository"
        return 1
    fi

    # Get the name of the current git repository
    local repo_name=$(basename $(command git rev-parse --show-toplevel))

    # Ensure the backup directory exists
    mkdir -p "$TLD/git-backups/$repo_name"

    # Create a backup of current changes
    local backup_file="$TLD/git-backups/$repo_name/reset-$(date +%Y%m%d_%H%M%S).diff"

    echo "Creating backup of uncommitted changes..."
    if command git diff HEAD > "$backup_file" && [[ -s "$backup_file" ]]; then
        echo "Backup saved to: $backup_file"
    else
        rm -f "$backup_file"
        echo "No uncommitted changes to backup"
    fi

    # Proceed with the reset
    command git "$@"
    echo "Reset completed. Backup available if needed."
}

# Safe git clean with confirmation
git_safe_clean() {
    echo "WARNING: This will permanently delete untracked files!"
    echo "Files to be deleted:"
    command git clean -n "$@"

    echo -n "Are you sure? (y/N): "
    read -r response
    case "$response" in
        [yY]|[yY][eE][sS])
            command git "$@"
            ;;
        *)
            echo "Operation cancelled"
            return 1
            ;;
    esac
}
