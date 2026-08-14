#!/bin/bash
# Test script to verify git aliases and colors are working

echo "🧪 Testing Git Integration and Colors..."
echo

# Test if gst alias is available
echo "Testing 'gst' alias:"
if command -v gst &> /dev/null; then
    echo "✅ gst command is available"
    echo "gst is aliased to: $(alias gst 2>/dev/null || echo "not found as alias")"
else
    echo "❌ gst command not found"
fi
echo

# Test other common git aliases
echo "Testing other git aliases:"
git_aliases=("ga" "gaa" "gc" "gco" "gd" "gl" "gp" "gst")
for alias_name in "${git_aliases[@]}"; do
    if alias "$alias_name" &>/dev/null; then
        echo "✅ $alias_name: $(alias "$alias_name" | cut -d"'" -f2)"
    else
        echo "❌ $alias_name: not found"
    fi
done
echo

# Test Oh My Zsh theme
echo "Testing Oh My Zsh theme:"
if [[ -n "$ZSH_THEME" ]]; then
    echo "✅ ZSH_THEME is set to: $ZSH_THEME"
else
    echo "❌ ZSH_THEME not set"
fi

if [[ -n "$ZSH" ]]; then
    echo "✅ ZSH directory: $ZSH"
    if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
        echo "✅ Oh My Zsh found and should be loaded"
    else
        echo "❌ Oh My Zsh script not found"
    fi
else
    echo "❌ ZSH variable not set"
fi
echo

# Test colors in terminal
echo "Testing terminal colors:"
echo -e "\033[31mRed text\033[0m"
echo -e "\033[32mGreen text\033[0m"
echo -e "\033[33mYellow text\033[0m"
echo -e "\033[34mBlue text\033[0m"
echo

# Test git status with colors (if in git repo)
if git rev-parse --git-dir &>/dev/null; then
    echo "Testing git status colors (in git repo):"
    git -c color.status=always status --porcelain=v1 2>/dev/null | head -5
else
    echo "Not in a git repository - cannot test git status colors"
fi

echo
echo "🏁 Test complete!"