#!/bin/bash
# Quick restore script to fix broken Oh My Zsh integration

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔧 Restoring working Oh My Zsh configuration..."

# Restore a simple, working Oh My Zsh config
cat > "$CONFIG_DIR/zshrc.d/core/002.environment.sh" << 'EOF'
#!/bin/bash

# Restored working Oh My Zsh configuration
UNAME=$(uname | tr "[:upper:]" "[:lower:]")

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="agnoster"

# Essential plugins for git aliases and colors
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# Performance settings (but don't break functionality)
ZSH_DISABLE_COMPFIX=true

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Ensure compinit is run
autoload -U compinit
compinit
EOF

echo "✅ Restored working configuration"
echo "📝 Please restart your shell: exec zsh"
echo "🧪 Then test with: ./scripts/test-git-colors.sh"