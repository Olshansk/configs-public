#!/bin/zsh

# Personal profile credential template. Copy with:
# make PROFILE=personal secrets-init

# AI providers
export DEEPGRAM_KEY=""
export OPENAI_API_KEY=""
export OPENROUTER_API_KEY=""
export ANTHROPIC_API_KEY=""
export CLAUDE_CODE_OAUTH_TOKEN=""

# Agent integrations
export CLAUDE_BOT_RENDER_PASS=""
export CLAUDE_BOT_TELEGRAM_BOT=""

# Cloud and infrastructure
export VULTR_API_KEY=""
export GROVE_PORTAL_API_KEY=""
export GROVE_PORTAL_APP_ID=""
export GROVE_SNAPSHOT_PASS=""
export VAULT_TOKEN=""
export VAULT_UNSEAL_KEY=""

# Local secret store
export SCRT_PASSWORD=""

# Pocket and database helpers
export POCKET_DISPATCHER_USERNAME=""
export POCKET_DISPATCHER_PASSWORD=""
export GROVE_PORTAL_DB_OLD_PASSWORD=""
export GROVE_PORTAL_DB_NEW_PASSWORD=""
export GROVE_DB_PASSWORD=""

# Optional credentials referenced by older helpers
export VULTR_PASSWORD=""
export GROVE_API_KEY=""
export SUPABASE_API_KEY=""
export POCKET_PRIVATE_KEY=""
