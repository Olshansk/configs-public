#!/bin/bash
# Start the LM Studio local server if needed and load a chosen model for pi.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
LMSTUDIO_HOME="${LMSTUDIO_HOME:-$HOME/.lmstudio}"

print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        ERROR)   echo -e "${RED}❌ ERROR: ${message}${NC}" ;;
        WARNING) echo -e "${YELLOW}⚠️  ${message}${NC}" ;;
        SUCCESS) echo -e "${GREEN}✅ ${message}${NC}" ;;
        INFO)    echo -e "${BLUE}ℹ️  ${message}${NC}" ;;
    esac
}

usage() {
    cat <<'EOF'
Usage:
  lms-server.sh [preset-or-model-key-or-path] [--identifier NAME] [--ttl SECONDS] [--context TOKENS] [--gpu VALUE] [--port PORT] [--cors]

Default context is 262144 tokens so pi can send its full system prompt,
AGENTS.md context, and tool schema without LM Studio rejecting the request.

Presets:
  qwen4b        -> qwen/qwen3-4b-2507
  qwen27b       -> qwen/qwen3.6-27b
  qwen-vl30b    -> qwen/qwen3-vl-30b
  qwen-coder30b -> qwen/qwen3-coder-30b
  gpt-oss20b    -> openai/gpt-oss-20b
  qwen25-7b     -> qwen2.5-7b-instruct

Examples:
  lms-server.sh qwen4b
  lms-server.sh qwen27b --ttl 3600
  lms-server.sh "$HOME/.lmstudio/hub/models/qwen/qwen3-4b-2507"
  lms-server.sh qwen/qwen3-4b-2507 --identifier local-qwen4b
EOF
}

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_status ERROR "Missing required command: $cmd"
        exit 1
    fi
}

resolve_model() {
    local candidate="$1"
    case "$candidate" in
        ""|qwen4b|qwen/qwen3-4b-2507|"$LMSTUDIO_HOME"/hub/models/qwen/qwen3-4b-2507)
            MODEL_KEY="qwen/qwen3-4b-2507"
            DEFAULT_IDENTIFIER="qwen3-4b-2507"
            ;;
        qwen27b|qwen/qwen3.6-27b|qwen/qwen3.6-27b@q4_k_m|"$LMSTUDIO_HOME"/models/lmstudio-community/Qwen3.6-27B-GGUF/Qwen3.6-27B-Q4_K_M.gguf)
            MODEL_KEY="qwen/qwen3.6-27b"
            DEFAULT_IDENTIFIER="qwen3.6-27b-q4_k_m"
            ;;
        qwen-vl30b|qwen3-vl-30b|qwen/qwen3-vl-30b)
            MODEL_KEY="qwen/qwen3-vl-30b"
            DEFAULT_IDENTIFIER="qwen3-vl-30b"
            ;;
        qwen-coder30b|qwen3-coder-30b|qwen/qwen3-coder-30b)
            MODEL_KEY="qwen/qwen3-coder-30b"
            DEFAULT_IDENTIFIER="qwen3-coder-30b"
            ;;
        gpt-oss20b|gpt-oss-20b|openai/gpt-oss-20b)
            MODEL_KEY="openai/gpt-oss-20b"
            DEFAULT_IDENTIFIER="gpt-oss-20b"
            ;;
        qwen25-7b|qwen2.5-7b-instruct|lmstudio-community/Qwen2.5-7B-Instruct-GGUF/Qwen2.5-7B-Instruct-Q4_K_M.gguf)
            MODEL_KEY="qwen2.5-7b-instruct"
            DEFAULT_IDENTIFIER="qwen2.5-7b-instruct"
            ;;
        "$LMSTUDIO_HOME"/hub/models/*)
            local tail="${candidate#"$LMSTUDIO_HOME"/hub/models/}"
            local publisher="${tail%%/*}"
            local model="${tail#*/}"
            MODEL_KEY="${publisher}/${model}"
            DEFAULT_IDENTIFIER="${model//[^A-Za-z0-9._-]/-}"
            ;;
        *)
            MODEL_KEY="$candidate"
            DEFAULT_IDENTIFIER="${candidate##*/}"
            DEFAULT_IDENTIFIER="${DEFAULT_IDENTIFIER//[^A-Za-z0-9._-]/-}"
            ;;
    esac
}

MODEL_INPUT="${1:-qwen4b}"
if [[ "${MODEL_INPUT}" == "-h" || "${MODEL_INPUT}" == "--help" ]]; then
    usage
    exit 0
fi
shift || true

IDENTIFIER=""
TTL="${LMSTUDIO_TTL:-3600}"
CONTEXT="${LMSTUDIO_CONTEXT:-262144}"
GPU="${LMSTUDIO_GPU:-}"
PORT="${LMSTUDIO_PORT:-1234}"
ENABLE_CORS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --identifier)
            IDENTIFIER="$2"
            shift 2
            ;;
        --ttl)
            TTL="$2"
            shift 2
            ;;
        --context|--context-length|-c)
            CONTEXT="$2"
            shift 2
            ;;
        --gpu)
            GPU="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --cors)
            ENABLE_CORS=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_status ERROR "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

require_cmd lms
require_cmd python3
resolve_model "$MODEL_INPUT"
IDENTIFIER="${IDENTIFIER:-$DEFAULT_IDENTIFIER}"

print_status INFO "Model key: ${MODEL_KEY}"
print_status INFO "Identifier: ${IDENTIFIER}"

if ! lms server status >/dev/null 2>&1; then
    print_status INFO "Starting LM Studio server on port ${PORT}"
    server_args=(server start --port "$PORT")
    if [[ "$ENABLE_CORS" == "1" ]]; then
        server_args+=(--cors)
    fi
    lms "${server_args[@]}"
else
    print_status SUCCESS "LM Studio server already running"
fi

load_args=(load "$MODEL_KEY" --yes --identifier "$IDENTIFIER")
if [[ -n "$TTL" ]]; then
    load_args+=(--ttl "$TTL")
fi
if [[ -n "$CONTEXT" ]]; then
    load_args+=(-c "$CONTEXT")
fi
if [[ -n "$GPU" ]]; then
    load_args+=(--gpu "$GPU")
fi

existing_model_key="$(lms ps --json 2>/dev/null | LMSTUDIO_IDENTIFIER="$IDENTIFIER" python3 -c 'import json, os, sys; ident=os.environ.get("LMSTUDIO_IDENTIFIER", ""); data=json.load(sys.stdin); match=next((item for item in data if item.get("identifier") == ident), None); print((match or {}).get("modelKey", ""))' 2>/dev/null)"

if [[ -n "$existing_model_key" ]]; then
    if [[ "$existing_model_key" == "$MODEL_KEY" ]]; then
        print_status SUCCESS "Model already loaded in LM Studio"
    else
        print_status ERROR "Identifier ${IDENTIFIER} is already in use by ${existing_model_key}"
        exit 1
    fi
else
    print_status INFO "Loading model into LM Studio"
    lms "${load_args[@]}"
fi

echo
print_status SUCCESS "LM Studio is ready"
echo -e "${CYAN}Quick test:${NC}"
echo -e "${CYAN}  curl -s http://127.0.0.1:${PORT}/v1/chat/completions \\
    -H 'Content-Type: application/json' \\
    -d '{\"model\":\"${IDENTIFIER}\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hello in five words.\"}]}'${NC}"
echo
echo -e "${CYAN}Use with pi:${NC}"
echo -e "${CYAN}  pi --provider lmstudio --model ${IDENTIFIER}${NC}"
echo -e "${CYAN}  pi --provider lmstudio --model ${IDENTIFIER} -p 'Reply OK only.'${NC}"
