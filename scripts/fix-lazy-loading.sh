#!/bin/bash
# Emergency fix for lazy loading recursion issues

echo "🔧 Fixing lazy loading issues..."

# Remove any problematic function wrappers
echo "Removing function wrappers..."
unfunction kubectl 2>/dev/null || true
unfunction docker 2>/dev/null || true
unfunction gcloud 2>/dev/null || true
unfunction gh 2>/dev/null || true
unfunction pyenv 2>/dev/null || true
unfunction nvm 2>/dev/null || true
unfunction node 2>/dev/null || true
unfunction npm 2>/dev/null || true
unfunction rbenv 2>/dev/null || true
unfunction conda 2>/dev/null || true

# Clear lazy loading tracking variables
unset _lazy_tools_loaded
unset _completion_loaded
unset _original_commands
unset _original_tools

echo "✅ Cleared lazy loading wrappers"

# Disable lazy loading temporarily
export DISABLE_LAZY_LOADING=1

echo "🚨 Lazy loading disabled temporarily"
echo "💡 To re-enable: unset DISABLE_LAZY_LOADING && exec zsh"
echo "🔄 Restart shell now: exec zsh"