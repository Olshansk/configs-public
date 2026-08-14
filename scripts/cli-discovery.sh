#!/usr/bin/env bash
set -euo pipefail

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}
LIMIT=${LIMIT:-10000}
HISTORY_SOURCE=${HISTORY_SOURCE:-ext}
HISTORY_FILE=${HISTORY_FILE:-}
QUIET=${QUIET:-0}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

command -v jq >/dev/null 2>&1 || { printf 'jq is required for CLI discovery.\n' >&2; exit 1; }
command -v zsh >/dev/null 2>&1 || { printf 'zsh is required for CLI discovery.\n' >&2; exit 1; }
[[ "$LIMIT" =~ ^[1-9][0-9]*$ ]] || { printf 'LIMIT must be a positive integer.\n' >&2; exit 2; }

case "$HISTORY_SOURCE" in
  ext) HISTORY_FILE=${HISTORY_FILE:-$HOME/.zsh_history_ext} ;;
  native) HISTORY_FILE=${HISTORY_FILE:-$HOME/.zsh_history} ;;
  *) printf 'HISTORY_SOURCE must be ext or native.\n' >&2; exit 2 ;;
esac

[[ -r "$HISTORY_FILE" ]] || { printf 'History file is not readable: %s\n' "$HISTORY_FILE" >&2; exit 1; }
[[ -r "$CONFIGS_DIR/apps/cli-tools.json" ]] || { printf 'Missing CLI inventory: %s\n' "$CONFIGS_DIR/apps/cli-tools.json" >&2; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
commands_file="$tmpdir/commands"

if [[ "$HISTORY_SOURCE" == ext ]]; then
  tail -n "$LIMIT" "$HISTORY_FILE" |
    awk '{ line = $0; if (match(line, /[|]\/[^|]*[[:space:]]*$/)) line = substr(line, 1, RSTART - 1); sub(/[[:space:]]+$/, "", line); print line }' >"$tmpdir/history"
else
  zsh -f -c 'fc -R -- "$1"; fc -ln -"$2"' _ "$HISTORY_FILE" "$LIMIT" >"$tmpdir/history" 2>"$tmpdir/history.err" || {
    cat "$tmpdir/history.err" >&2
    exit 1
  }
fi

zsh -f -c '
  history_file=$1
  while IFS= read -r line; do
    tokens=("${(@z)line}")
    expect_command=1
    for token in "${tokens[@]}"; do
      case "$token" in
        ";"|"&&"|"||"|"|"|"&") expect_command=1; continue ;;
      esac
      [[ -z "$token" ]] && continue
      if (( expect_command )); then
        case "$token" in
          sudo|command|builtin|noglob|time|env) continue ;;
          [A-Za-z_][A-Za-z0-9_]*=*|-*|"("|")") continue ;;
        esac
        print -r -- "$token"
        expect_command=0
      fi
    done
  done <"$history_file"
' cli-tokenizer "$tmpdir/history" >"$commands_file"

counts="$tmpdir/counts"
sort "$commands_file" | uniq -c | awk '{$1=$1; print}' | sort -k2,2 >"$counts"
timestamp=$(date +%Y%m%d-%H%M%S)
report_dir="$CONFIGS_DIR/.local/cli-discovery/$PROFILE"
report_path="$report_dir/cli-discovery-$timestamp.json"
mkdir -p "$report_dir"

commands_json=$(
  while read -r count command_name; do
    [[ -n "$command_name" ]] || continue
    desired_classification=$(jq -r --arg command "$command_name" '[.tools[] | select(.command == $command) | .classification][0] // empty' "$CONFIGS_DIR/apps/cli-tools.json")
    path=$(command -v "$command_name" 2>/dev/null || true)
    installed=false
    origin=unknown
    classification=${desired_classification:-unknown}
    case "$command_name" in
      .|..|cd|pwd|echo|printf|read|export|source|true|false|test|set|unset|alias|unalias|command|builtin|exec|eval|shift|return|type|whence|which|hash|jobs|fg|bg|wait|kill|umask|ulimit|history|fc|pushd|popd|dirs)
        installed=true
        origin=system
        classification=system
        path=
        ;;
    esac
    if [[ "$classification" != system && -n "$path" ]]; then
      installed=true
      case "$path" in
        /bin/*|/sbin/*|/usr/bin/*|/usr/sbin/*) origin=system; [[ -n "$desired_classification" ]] || classification=system ;;
        */.venv/bin/*|*/node_modules/.bin/*|*/target/debug/*|*/target/release/*) origin=project-local; [[ -n "$desired_classification" ]] || classification=project-local ;;
        /opt/homebrew/*|/usr/local/Cellar/*|/usr/local/opt/*) origin=homebrew; [[ -n "$desired_classification" ]] || classification=managed ;;
        "$HOME/.local/bin/"*|"$HOME/bin/"*|/Applications/*) origin=manual; [[ -n "$desired_classification" ]] || classification=manual ;;
        *) origin=other ;;
      esac
    fi
    jq -cn --arg command "$command_name" --argjson count "$count" --arg classification "$classification" --arg origin "$origin" --argjson installed "$installed" '{command: $command, count: $count, classification: $classification, origin: $origin, installed: $installed}'
  done <"$counts" | jq -s .
)

jq -n --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg profile "$PROFILE" --arg history_source "$HISTORY_SOURCE" --arg history_file "$(basename "$HISTORY_FILE")" --argjson limit "$LIMIT" --argjson commands "$commands_json" '{schema_version: 1, generated_at: $generated_at, profile: $profile, history_source: $history_source, history_file: $history_file, limit: $limit, commands: $commands}' >"$report_path"

if [[ "$QUIET" == 1 ]]; then
  printf '%s\n' "$report_path"
else
  printf 'CLI discovery report: %s\n' "$report_path"
  jq -r '.commands | sort_by(-.count) | .[:25][] | "\(.count)\t\(.command)\t\(.classification)\t\(.origin)"' "$report_path" |
    awk 'BEGIN { printf "%-8s %-20s %-16s %s\n", "Uses", "Command", "Class", "Origin" } { printf "%-8s %-20s %-16s %s\n", $1, $2, $3, $4 }'
fi
