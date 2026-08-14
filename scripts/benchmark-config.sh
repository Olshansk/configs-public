#!/bin/bash
# Configuration Performance Benchmark Script
# Measures shell startup time and identifies slow-loading modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIGS_DIR="${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="${CONFIGS_DIR}/zshrc.d"
RUNS=${1:-5}  # Number of test runs, default 5

echo -e "${BLUE}🚀 Benchmarking shell configuration performance...${NC}\n"

# Function to measure loading time
measure_load_time() {
    local config_path="$1"
    local iterations="$2"
    local total_time=0

    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s.%N)
        zsh -c "source '$config_path'" 2>/dev/null
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
    done

    # Calculate average
    local avg_time=$(echo "scale=4; $total_time / $iterations" | bc -l)
    echo "$avg_time"
}

# Function to measure individual module performance
benchmark_modules() {
    echo -e "${BLUE}📊 Benchmarking individual modules...${NC}\n"

    local modules=()
    local times=()

    # Find all shell files
    while IFS= read -r -d '' file; do
        modules+=("$file")
    done < <(find "$CONFIG_DIR" -name "*.sh" -print0 | sort -z)

    printf "%-50s %s\n" "Module" "Avg Time (s)"
    printf "%-50s %s\n" "------" "-----------"

    for module in "${modules[@]}"; do
        local module_name=$(basename "$module")
        local avg_time=$(measure_load_time "$module" 3)
        times+=("$avg_time")

        # Color code based on performance
        if (( $(echo "$avg_time > 0.1" | bc -l) )); then
            printf "${RED}%-50s %s${NC}\n" "$module_name" "$avg_time"
        elif (( $(echo "$avg_time > 0.05" | bc -l) )); then
            printf "${YELLOW}%-50s %s${NC}\n" "$module_name" "$avg_time"
        else
            printf "${GREEN}%-50s %s${NC}\n" "$module_name" "$avg_time"
        fi
    done

    echo
}

# Function to benchmark overall startup time
benchmark_startup() {
    echo -e "${BLUE}⏱️  Benchmarking overall startup time...${NC}\n"

    local temp_zshrc=$(mktemp)
    cat > "$temp_zshrc" << 'EOF'
# Temporary zshrc for benchmarking
source "${CONFIGS_DIR}/.zshrc"
EOF

    local total_time=0
    local times=()

    for ((i=1; i<=RUNS; i++)); do
        local start_time=$(date +%s.%N)
        ZDOTDIR="$(dirname "$temp_zshrc")" ZSHRC_DEBUG=1 zsh -c "source '$temp_zshrc'" 2>/dev/null
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        times+=("$duration")
        total_time=$(echo "$total_time + $duration" | bc -l)
        printf "Run %d: %.4fs\n" "$i" "$duration"
    done

    # Calculate statistics
    local avg_time=$(echo "scale=4; $total_time / $RUNS" | bc -l)

    # Find min and max
    local min_time=${times[0]}
    local max_time=${times[0]}

    for time in "${times[@]}"; do
        if (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
        fi
        if (( $(echo "$time > $max_time" | bc -l) )); then
            max_time=$time
        fi
    done

    echo
    echo "=== STARTUP PERFORMANCE ==="
    printf "Average time: %.4fs\n" "$avg_time"
    printf "Min time:     %.4fs\n" "$min_time"
    printf "Max time:     %.4fs\n" "$max_time"

    # Performance assessment
    if (( $(echo "$avg_time > 1.0" | bc -l) )); then
        echo -e "${RED}❌ Startup time is slow (>1s)${NC}"
        echo "Consider lazy loading more modules or optimizing heavy configurations"
    elif (( $(echo "$avg_time > 0.5" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Startup time is moderate (>0.5s)${NC}"
        echo "Room for improvement with lazy loading"
    else
        echo -e "${GREEN}✅ Startup time is good (<0.5s)${NC}"
    fi

    rm -f "$temp_zshrc"
    echo
}

# Function to identify heavy modules
identify_heavy_modules() {
    echo -e "${BLUE}🔍 Identifying performance bottlenecks...${NC}\n"

    # List modules that take longer than 50ms
    echo "Modules taking >50ms to load:"
    find "$CONFIG_DIR" -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        local module_name=$(basename "$file")
        local load_time=$(measure_load_time "$file" 1)

        if (( $(echo "$load_time > 0.05" | bc -l) )); then
            printf "${YELLOW}  %-40s %.4fs${NC}\n" "$module_name" "$load_time"

            # Suggest optimizations
            if grep -q "source.*completion" "$file" 2>/dev/null; then
                echo "    💡 Consider lazy loading completions"
            fi
            if grep -q "eval.*init" "$file" 2>/dev/null; then
                echo "    💡 Consider lazy loading tool initialization"
            fi
            if grep -q "PATH.*=" "$file" 2>/dev/null; then
                echo "    💡 PATH modifications detected"
            fi
        fi
    done

    echo
}

# Function to suggest optimizations
suggest_optimizations() {
    echo -e "${BLUE}💡 Optimization Suggestions${NC}\n"

    local suggestions=()

    # Check for common performance issues
    if find "$CONFIG_DIR" -name "*.sh" -exec grep -l "source.*completion" {} \; | head -1 >/dev/null; then
        suggestions+=("Implement lazy loading for shell completions")
    fi

    if find "$CONFIG_DIR" -name "*.sh" -exec grep -l "eval.*init" {} \; | head -1 >/dev/null; then
        suggestions+=("Lazy load tool initializations (nvm, pyenv, etc.)")
    fi

    if find "$CONFIG_DIR" -name "*.sh" -exec grep -l "export PATH" {} \; | wc -l | grep -q "[5-9]"; then
        suggestions+=("Consolidate PATH modifications into a single module")
    fi

    local heavy_modules=$(find "$CONFIG_DIR" -name "*.sh" -print0 | while IFS= read -r -d '' file; do
        local load_time=$(measure_load_time "$file" 1)
        if (( $(echo "$load_time > 0.1" | bc -l) )); then
            echo "$(basename "$file")"
        fi
    done)

    if [[ -n "$heavy_modules" ]]; then
        suggestions+=("Profile and optimize slow modules: $(echo "$heavy_modules" | tr '\n' ' ')")
    fi

    # Display suggestions
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        for i in "${!suggestions[@]}"; do
            printf "%d. %s\n" $((i+1)) "${suggestions[i]}"
        done
    else
        echo -e "${GREEN}✅ No obvious optimization opportunities found${NC}"
    fi

    echo
}

# Main function
main() {
    # Check dependencies
    if ! command -v bc &>/dev/null; then
        echo -e "${RED}❌ ERROR: 'bc' calculator not found. Please install it first.${NC}"
        exit 1
    fi

    if [[ ! -d "$CONFIG_DIR" ]]; then
        echo -e "${RED}❌ ERROR: Configuration directory not found: $CONFIG_DIR${NC}"
        exit 1
    fi

    echo "Running $RUNS iterations for startup benchmark..."
    echo "Configuration directory: $CONFIG_DIR"
    echo

    benchmark_startup
    benchmark_modules
    identify_heavy_modules
    suggest_optimizations

    echo -e "${GREEN}🎯 Benchmark complete!${NC}"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
