#!/bin/bash
# Lazy Loading for Tool Initializations
# Tools only initialize when first used, dramatically improving startup time

# Safety check - skip if lazy loading is disabled
[[ "$DISABLE_LAZY_LOADING" == "1" ]] && return 0

# Track what's been loaded
typeset -A _lazy_tools_loaded

# Store original tool paths to avoid recursion
typeset -A _original_tools

# Function to create lazy loader for any tool - RECURSION-SAFE
lazy_load_tool() {
    local tool_name="$1"
    local init_command="$2"
    local check_command="${3:-$tool_name}"

    # Store original command path
    _original_tools[$tool_name]=$(command -v "$tool_name" 2>/dev/null)

    # Create wrapper function
    eval "${tool_name}() {
        # Load tool on first use
        if [[ -z \"\$_lazy_tools_loaded[$tool_name]\" ]]; then
            _lazy_tools_loaded[$tool_name]=1
            if [[ -n \"\$_original_tools[$tool_name]\" ]]; then
                eval \"$init_command\" 2>/dev/null || true
            fi
        fi

        # Remove wrapper and call real command using stored path
        unfunction $tool_name 2>/dev/null || true
        local original_cmd=\"\$_original_tools[$tool_name]\"
        if [[ -n \"\$original_cmd\" ]]; then
            \"\$original_cmd\" \"\$@\"
        else
            command $tool_name \"\$@\"
        fi
    }"
}

# Lazy load pyenv
if command -v pyenv &>/dev/null; then
    lazy_load_tool pyenv "
        export PYENV_ROOT=\"\$HOME/.pyenv\"
        export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
        eval \"\$(pyenv init --path)\"
        eval \"\$(pyenv init -)\"
    "
fi

# node/npm/nvm: handled by fnm in zshrc.d/development/005.node.sh.
# fnm initializes in ~5ms so no lazy wrapper is needed; the previous nvm
# lazy block lived here and caused a multi-second freeze on first `npm`
# call per shell.

# Lazy load rbenv
if command -v rbenv &>/dev/null; then
    lazy_load_tool rbenv "eval \"\$(rbenv init - zsh)\""
fi

# Lazy load jenv (Java environment manager)
if command -v jenv &>/dev/null; then
    lazy_load_tool jenv "eval \"\$(jenv init -)\""
fi

# Lazy load conda
if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    conda() {
        if [[ -z "$_lazy_tools_loaded[conda]" ]]; then
            _lazy_tools_loaded[conda]=1
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        fi

        unfunction conda
        conda "$@"
    }
elif [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    conda() {
        if [[ -z "$_lazy_tools_loaded[conda]" ]]; then
            _lazy_tools_loaded[conda]=1
            source "$HOME/anaconda3/etc/profile.d/conda.sh"
        fi

        unfunction conda
        conda "$@"
    }
fi

# Lazy load asdf
if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    asdf() {
        if [[ -z "$_lazy_tools_loaded[asdf]" ]]; then
            _lazy_tools_loaded[asdf]=1
            source "$HOME/.asdf/asdf.sh"
            source "$HOME/.asdf/completions/asdf.bash"
        fi

        unfunction asdf
        asdf "$@"
    }
fi

# Lazy load sdkman
if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    sdk() {
        if [[ -z "$_lazy_tools_loaded[sdk]" ]]; then
            _lazy_tools_loaded[sdk]=1
            source "$HOME/.sdkman/bin/sdkman-init.sh"
        fi

        unfunction sdk
        sdk "$@"
    }
fi

# Lazy load cargo (Rust)
if [[ -f "$HOME/.cargo/env" ]]; then
    cargo() {
        if [[ -z "$_lazy_tools_loaded[cargo]" ]]; then
            _lazy_tools_loaded[cargo]=1
            source "$HOME/.cargo/env"
        fi

        unfunction cargo
        command cargo "$@"
    }

    rustc() {
        cargo --version &>/dev/null  # Trigger cargo loading
        unfunction rustc
        command rustc "$@"
    }
fi

# Function to preload tools when entering relevant directories
auto_load_tools() {
    # Check for project files and preload relevant tools
    # .nvmrc auto-switching is handled by `fnm env --use-on-cd` (see 005.node.sh).

    if [[ -f ".python-version" ]] && command -v pyenv &>/dev/null; then
        # Keep directory-change hooks silent so terminal cwd tracking stays intact.
        pyenv local >/dev/null 2>&1 || true
    fi

    if [[ -f "Gemfile" ]] && command -v rbenv &>/dev/null; then
        # Keep directory-change hooks silent so terminal cwd tracking stays intact.
        rbenv local >/dev/null 2>&1 || true
    fi

    if [[ -f "environment.yml" || -f "conda.yml" ]] && command -v conda &>/dev/null; then
        # Keep directory-change hooks silent so terminal cwd tracking stays intact.
        conda info >/dev/null 2>&1 || true
    fi
}

# Auto-load tools when changing directories
add-zsh-hook chpwd auto_load_tools
