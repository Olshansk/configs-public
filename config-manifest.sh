#!/usr/bin/env bash

# Public portable configuration manifest.
# AI runtime settings, histories, application state, and project trust data are
# intentionally not managed here.
CONFIG_MANIFEST=(
  "shell-zshrc|link|all|$CONFIGS_DIR/.zshrc|$HOME/.zshrc"
  "shell-bashrc|link|all|$CONFIGS_DIR/.bashrc|$HOME/.bashrc"
  "shell-profile|link|all|$CONFIGS_DIR/.profile|$HOME/.profile"
  "ghostty|link|all|$CONFIGS_DIR/profiles/$PROFILE/macos/shared/ghostty/config|$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  "agent-claude|agent-link|personal|$AGENT_SKILLS_DIR/agents/AGENTS.md|$HOME/.claude/CLAUDE.md"
  "agent-codex|agent-link|personal|$AGENT_SKILLS_DIR/agents/AGENTS.md|$HOME/.codex/AGENTS.md"
  "agent-gemini|agent-link|personal|$AGENT_SKILLS_DIR/agents/MEMORIES.md|$HOME/.gemini/GEMINI.md"
)
