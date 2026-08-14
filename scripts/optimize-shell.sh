#!/bin/bash
# Shell Performance Optimization Script
# Applies various optimizations to improve shell startup time

set -e

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC_FILE="$HOME/.zshrc"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local status=$1
    local message=$2
    case "$status" in
        "ERROR")   echo -e "${RED}❌ ERROR: $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  WARNING: $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "INFO")    echo -e "${BLUE}ℹ️  $message${NC}" ;;
    esac
}

# Function to add environment variables to shell profile
add_optimization_vars() {
    local shell_file="$1"

    if ! grep -q "ZSHRC_FAST_MODE" "$shell_file" 2>/dev/null; then
        cat >> "$shell_file" << 'EOF'

# Shell Performance Optimizations
export ZSHRC_FAST_MODE=1          # Enable ultra-fast loading
export DISABLE_AUTO_UPDATE=true   # Disable Oh My Zsh auto-updates
export DISABLE_UPDATE_PROMPT=true # Disable update prompts
# export ZSHRC_DEBUG=1             # Uncomment to see load times

EOF
        print_status "SUCCESS" "Added optimization variables to $shell_file"
    else
        print_status "INFO" "Optimization variables already present in $shell_file"
    fi
}

# Function to optimize zsh settings
optimize_zsh_settings() {
    local zsh_settings="$HOME/.zshenv"

    if [[ ! -f "$zsh_settings" ]]; then
        cat > "$zsh_settings" << 'EOF'
# Zsh Performance Optimizations
# Disable compinit security check (speeds up completion loading)
ZSH_DISABLE_COMPFIX=true

# Skip loading system-wide profiles for speed
setopt NO_GLOBAL_RCS

# Optimize history settings
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Faster completion
setopt AUTO_LIST
setopt AUTO_MENU
setopt ALWAYS_TO_END
unsetopt MENU_COMPLETE
unsetopt FLOW_CONTROL

EOF
        print_status "SUCCESS" "Created optimized .zshenv"
    else
        print_status "INFO" ".zshenv already exists"
    fi
}

# Function to benchmark before and after
run_benchmark() {
    local mode="$1"

    if [[ -x "$CONFIG_DIR/scripts/benchmark-config.sh" ]]; then
        print_status "INFO" "Running benchmark ($mode)..."
        local result=$("$CONFIG_DIR/scripts/benchmark-config.sh" 3 2>/dev/null | grep "Average time:" | awk '{print $3}')
        echo "$result"
    else
        echo "N/A"
    fi
}

# Main optimization function
main() {
    echo -e "${BLUE}🚀 Shell Performance Optimization${NC}\n"

    # Backup current shell configuration
    local backup_dir="$HOME/.config-backup-optimization-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    [[ -f "$ZSHRC_FILE" ]] && cp "$ZSHRC_FILE" "$backup_dir/"
    [[ -f "$HOME/.zshenv" ]] && cp "$HOME/.zshenv" "$backup_dir/"

    print_status "INFO" "Backup created at: $backup_dir"

    # Run initial benchmark
    print_status "INFO" "Running initial benchmark..."
    local before_time=$(run_benchmark "before")

    # Apply optimizations
    print_status "INFO" "Applying optimizations..."

    # 1. Add optimization environment variables
    add_optimization_vars "$ZSHRC_FILE"

    # 2. Optimize zsh settings
    optimize_zsh_settings

    # 3. Create fast startup aliases
    if ! grep -q "alias zsh-fast" "$ZSHRC_FILE" 2>/dev/null; then
        cat >> "$ZSHRC_FILE" << 'EOF'

# Quick shell optimization aliases
alias zsh-fast='export ZSHRC_FAST_MODE=1 && exec zsh'
alias zsh-full='export ZSHRC_FAST_MODE=0 && export FORCE_LOAD_ALL=1 && exec zsh'
alias zsh-debug='export ZSHRC_DEBUG=1 && exec zsh'
alias zsh-benchmark='${CONFIG_DIR}/scripts/benchmark-config.sh'

EOF
        print_status "SUCCESS" "Added optimization aliases"
    fi

    print_status "SUCCESS" "Optimizations applied!"

    echo
    echo "=== OPTIMIZATION COMPLETE ==="
    print_status "INFO" "Initial startup time: ${before_time:-N/A}"

    echo
    echo "Next steps:"
    echo "1. Restart your shell to apply changes:"
    echo "   ${YELLOW}exec zsh${NC}"
    echo
    echo "2. Use these new commands:"
    echo "   ${YELLOW}zsh-fast${NC}      # Ultra-fast startup mode"
    echo "   ${YELLOW}zsh-full${NC}      # Load all modules"
    echo "   ${YELLOW}zsh-debug${NC}     # Debug mode with timing"
    echo "   ${YELLOW}zsh-benchmark${NC} # Run performance test"
    echo
    echo "3. Benchmark the improvements:"
    echo "   ${YELLOW}./scripts/benchmark-config.sh${NC}"
    echo
    print_status "INFO" "Configuration backup: $backup_dir"
}

# Usage information
show_usage() {
    echo "Usage: $0 [--help]"
    echo
    echo "This script optimizes your shell configuration for faster startup times."
    echo
    echo "Optimizations applied:"
    echo "  • Enable fast mode loading (ZSHRC_FAST_MODE=1)"
    echo "  • Disable Oh My Zsh auto-updates"
    echo "  • Optimize zsh completion settings"
    echo "  • Add performance monitoring aliases"
    echo "  • Create .zshenv with performance settings"
    echo
    echo "Options:"
    echo "  --help    Show this help message"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_usage
        exit 0
        ;;
    "")
        main
        ;;
    *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
