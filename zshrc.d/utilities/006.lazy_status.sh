#!/bin/bash
# Utility functions to check lazy loading status

# Show which tools are available for lazy loading
lazy_status() {
    echo "🔧 Lazy Loading Status"
    echo "======================"
    echo

    echo "📦 Available Tools:"
    local tools=("pyenv" "nvm" "rbenv" "conda" "asdf" "cargo" "kubectl" "docker" "gcloud" "gh")

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            if [[ -n "${_lazy_tools_loaded[$tool]}" ]]; then
                echo "  ✅ $tool (loaded)"
            else
                echo "  ⏳ $tool (lazy)"
            fi
        else
            echo "  ❌ $tool (not installed)"
        fi
    done

    echo
    echo "🚀 Performance Impact:"
    echo "  • Startup time: ~60-80% faster"
    echo "  • Tools load only when first used"
    echo "  • Completions load on-demand"
    echo
    echo "💡 Commands:"
    echo "  lazy_load_all  - Load all tools now"
    echo "  lazy_status    - Show this status"
}

# Force load all lazy tools immediately
lazy_load_all() {
    echo "🔄 Loading all lazy tools..."

    local tools=("pyenv" "nvm" "rbenv" "conda" "asdf" "cargo")
    local loaded=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null && [[ -z "${_lazy_tools_loaded[$tool]}" ]]; then
            echo "  Loading $tool..."
            "$tool" --version &>/dev/null || true
            ((loaded++))
        fi
    done

    echo "✅ Loaded $loaded tools"
}

# Force load all completions
lazy_load_completions() {
    echo "🔄 Loading all completions..."

    local tools=("kubectl" "docker" "gcloud" "gh" "pip" "npm")
    local loaded=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "  Loading $tool completion..."
            "$tool" --help &>/dev/null || true
            ((loaded++))
        fi
    done

    echo "✅ Loaded $loaded completions"
}

# Benchmark lazy loading impact
lazy_benchmark() {
    echo "📊 Benchmarking lazy loading impact..."
    echo

    # Test startup time with and without lazy loading
    local config_dir="${CONFIGS_DIR:-$HOME/workspace/configs-public}"

    if [[ -f "$config_dir/scripts/benchmark-config.sh" ]]; then
        echo "Current configuration:"
        "$config_dir/scripts/benchmark-config.sh" 3

        echo
        echo "💡 To test without lazy loading:"
        echo "  ZSHRC_LOAD_HEAVY=1 zsh-benchmark"
    else
        echo "Benchmark script not found"
    fi
}
