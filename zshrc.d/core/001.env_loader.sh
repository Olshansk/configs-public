# Profile-scoped environment and secret loader.
#
# Committed, non-secret values live in profiles/<profile>/env.sh. Credentials
# live outside Git in ~/.config/dotfiles/profiles/<profile>/secrets.sh or the
# ignored .local/profiles/<profile>/secrets.sh fallback.

if [[ -n "${ZSH_VERSION:-}" ]]; then
    _env_loader_source="${(%):-%N}"
else
    _env_loader_source="${BASH_SOURCE[0]}"
fi
_config_root="$(cd "$(dirname "$_env_loader_source")/../.." && pwd)"

_dotfiles_profile="${DOTFILES_PROFILE:-}"
if [[ -z "$_dotfiles_profile" && -f "${_config_root}/.local/active-profile" ]]; then
    _dotfiles_profile="$(<"${_config_root}/.local/active-profile")"
fi

case "$_dotfiles_profile" in
    personal|work) ;;
    "")
        print -u2 -- "⚠️ Dotfiles profile is not selected; profile env and secrets were not loaded."
        print -u2 -- "   Run: make PROFILE=personal|work APPLY=1 profile-use"
        ;;
    *)
        print -u2 -- "⚠️ Invalid dotfiles profile '$_dotfiles_profile'; profile env and secrets were not loaded."
        _dotfiles_profile=""
        ;;
esac

_dotfiles_private_file() {
    local file="$1"
    local mode=""

    [[ -f "$file" && -O "$file" ]] || return 1
    mode="$(stat -f '%Lp' "$file" 2>/dev/null || stat -c '%a' "$file" 2>/dev/null)"
    [[ "$mode" == "600" || "$mode" == "400" ]]
}

if [[ -n "$_dotfiles_profile" ]]; then
    _profile_env="${_config_root}/profiles/${_dotfiles_profile}/env.sh"
    if [[ -r "$_profile_env" ]]; then
        source "$_profile_env"
    fi

    for _secrets_file in \
        "${HOME}/.config/dotfiles/profiles/${_dotfiles_profile}/secrets.sh" \
        "${_config_root}/.local/profiles/${_dotfiles_profile}/secrets.sh"; do
        [[ -f "$_secrets_file" ]] || continue
        if ! _dotfiles_private_file "$_secrets_file"; then
            print -u2 -- "⚠️ Refusing insecure secrets file: $_secrets_file (must be owned by you and mode 600 or 400)"
            continue
        fi

        # shellcheck disable=SC1090
        source "$_secrets_file"
        break
    done
fi

if [[ -f "${HOME}/.config/dotfiles/secrets.sh" || -f "${_config_root}/secrets.sh" || \
      -f "${HOME}/.config/dotfiles/.env" || -f "${_config_root}/.env" ]]; then
    print -u2 -- "⚠️ Legacy unscoped .env/secrets.sh found but not loaded; migrate values with make PROFILE=<profile> secrets-init."
fi

unset -f _dotfiles_private_file
unset _secrets_file _profile_env _dotfiles_profile _env_loader_source _config_root

# Function to check if required environment variables are set
check_env_var() {
    local var_name="$1"
    local friendly_name="${2:-$var_name}"

    if [[ -z "${(P)var_name}" ]]; then
        echo "Warning: $friendly_name not set. Add $var_name to the active profile's secrets.sh."
        return 1
    fi
    return 0
}
