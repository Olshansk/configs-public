#!/bin/bash
# Configuration Validation Script
# Validates all shell configuration files for syntax errors and common issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration directory
CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="${CONFIGS_DIR}/zshrc.d"
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 Validating shell configuration files...${NC}\n"

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case "$status" in
        "ERROR")
            echo -e "${RED}❌ ERROR: $message${NC}"
            ERRORS=$((ERRORS + 1))
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to validate shell syntax
validate_syntax() {
    local file="$1"

    # Skip if not a shell file
    if [[ ! "$file" =~ \.(sh|zsh|bash)$ ]]; then
        return 0
    fi

    print_status "INFO" "Checking syntax: $(basename "$file")"

    # Check zsh syntax
    if ! zsh -n "$file" 2>/dev/null; then
        print_status "ERROR" "Syntax error in $file"
        zsh -n "$file" 2>&1 | sed 's/^/  /'
        return 1
    fi

    return 0
}

# Function to check for common issues
check_common_issues() {
    local file="$1"

    # Check for hardcoded paths
    if grep -q '/Users/[^/]*/' "$file" 2>/dev/null; then
        print_status "WARNING" "Hardcoded user paths in $(basename "$file")"
        grep -n '/Users/[^/]*/' "$file" | head -3 | sed 's/^/  /'
    fi

    # Check for missing function declarations
    if grep -q '^[a-zA-Z_][a-zA-Z0-9_]*()' "$file" 2>/dev/null; then
        local func_count=$(grep -c '^[a-zA-Z_][a-zA-Z0-9_]*()' "$file")
        print_status "INFO" "Found $func_count function(s) in $(basename "$file")"
    fi
}

# Function to check dependencies
check_dependencies() {
    local file="$1"

    # Extract command dependencies
    local commands=($(grep -oE '\bcommand -v [a-zA-Z0-9_-]+' "$file" 2>/dev/null | awk '{print $3}' | sort -u))

    if [[ ${#commands[@]} -gt 0 ]]; then
        print_status "INFO" "Dependencies in $(basename "$file"): ${commands[*]}"

        for cmd in "${commands[@]}"; do
            if ! command -v "$cmd" &>/dev/null; then
                print_status "INFO" "Optional dependency unavailable: $cmd ($(basename "$file"))"
            fi
        done
    fi
}

# TODO_TECHDEBT: Review Git history for previously committed credentials and
# rotate any values that may still be valid. Defer this until the current-file
# validation workflow is stable; use a history-aware secret scanner rather than
# expanding this runtime configuration check to inspect repository history.

# Function to validate directory structure
validate_structure() {
    local expected_dirs=("core" "development" "utilities")

    print_status "INFO" "Validating directory structure..."

    for dir in "${expected_dirs[@]}"; do
        if [[ -d "$CONFIG_DIR/$dir" ]]; then
            local file_count=$(find "$CONFIG_DIR/$dir" -name "*.sh" | wc -l)
            print_status "SUCCESS" "$dir/ directory exists with $file_count files"
        else
            print_status "WARNING" "Missing expected directory: $dir/"
        fi
    done
}

# Function to check for load order issues
check_load_order() {
    print_status "INFO" "Checking load order..."

    local all_files=()
    while IFS= read -r -d '' file; do
        all_files+=("$file")
    done < <(find "$CONFIG_DIR" -name "*.sh" -print0 | sort -z)

    # Check for numerical prefixes
    for file in "${all_files[@]}"; do
        local basename=$(basename "$file")
        [[ "$basename" == "loader.sh" ]] && continue
        if [[ ! "$basename" =~ ^[0-9]{3}\. ]]; then
            print_status "WARNING" "Non-standard numbering in $(basename "$file")"
        fi
    done
}

# Main validation loop
main() {
    # Check if config directory exists
    if [[ ! -d "$CONFIG_DIR" ]]; then
        print_status "ERROR" "Configuration directory not found: $CONFIG_DIR"
        exit 1
    fi

    # Validate directory structure
    validate_structure
    echo

    # Check load order
    check_load_order
    echo

    # Find and validate all shell files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$CONFIG_DIR" -name "*.sh" -print0)

    if [[ ${#files[@]} -eq 0 ]]; then
        print_status "WARNING" "No shell files found in $CONFIG_DIR"
        exit 0
    fi

    print_status "INFO" "Found ${#files[@]} shell files to validate"
    echo

    # Validate each file
    for file in "${files[@]}"; do
        echo "--- $(basename "$file") ---"

        validate_syntax "$file"
        check_common_issues "$file"
        check_dependencies "$file"

        echo
    done

    # Summary
    echo "=== VALIDATION SUMMARY ==="
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        print_status "SUCCESS" "All configurations validated successfully!"
    else
        print_status "INFO" "Validation completed with $ERRORS error(s) and $WARNINGS warning(s)"
        if [[ $ERRORS -gt 0 ]]; then
            echo -e "${RED}Please fix errors before proceeding${NC}"
            exit 1
        fi
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
