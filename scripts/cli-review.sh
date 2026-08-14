#!/usr/bin/env bash
set -euo pipefail

CONFIGS_DIR=${CONFIGS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
PROFILE_INPUT=${PROFILE:-}

source "$CONFIGS_DIR/scripts/profile.sh"
resolve_profile "$PROFILE_INPUT"

report_path=$(QUIET=1 PROFILE="$PROFILE" LIMIT="${LIMIT:-10000}" HISTORY_SOURCE="${HISTORY_SOURCE:-ext}" "$CONFIGS_DIR/scripts/cli-discovery.sh")
inventory="$CONFIGS_DIR/apps/cli-tools.json"

printf 'CLI review for profile: %s\n' "$PROFILE"
printf 'Report: %s\n\n' "$report_path"
printf '%-3s %-16s %-18s %6s %-16s %-15s %-9s %-10s %s\n' '#' 'Recommendation' 'Command' 'Uses' 'Classification' 'Install source' 'Installed' 'Confidence' 'Manual action'
printf '%-3s %-16s %-18s %6s %-16s %-15s %-9s %-10s %s\n' '---' '----------------' '------------------' '------' '----------------' '---------------' '---------' '----------' '-------------'

rows=$(
  jq -r --slurpfile inventory "$inventory" '
    .commands | sort_by(-.count, .command)[]
    | . as $command
    | ($inventory[0].tools | map(select(.command == $command.command)) | .[0]) as $desired
    | if $command.classification == "system" or $command.classification == "project-local" then
        ["IGNORE", $command.command, ($command.count|tostring), $command.classification, $command.origin, ($command.installed|tostring), "high", "No inventory change"]
      elif $desired then
        ["KEEP", $command.command, ($command.count|tostring), $desired.classification, $command.origin, ($command.installed|tostring), "high", "No change"]
      elif $command.installed and $command.count >= 2 then
        ["ADD", $command.command, ($command.count|tostring), $command.classification, $command.origin, "true", "high", "Review inventory/Brewfile"]
      elif (($command.installed | not) and $command.classification == "unknown" and $command.count >= 2) then
        ["REVIEW", $command.command, ($command.count|tostring), $command.classification, $command.origin, "false", "medium", "Check alias/function or installer"]
      elif $command.count >= 2 then
        ["ADD", $command.command, ($command.count|tostring), $command.classification, $command.origin, "false", "medium", "Identify installer"]
      else
        ["IGNORE", $command.command, ($command.count|tostring), $command.classification, $command.origin, ($command.installed|tostring), "low", "Insufficient usage"]
      end
    | @tsv
  ' "$report_path"
  jq -r --slurpfile report "$report_path" '
    .tools[]
    | . as $desired
    | (($report[0].commands | map(select(.command == $desired.command)) | .[0].count) // 0) as $count
    | select($count == 0 and ((.pinned // false) | not))
    | ["REMOVE", $desired.command, "0", $desired.classification, "unknown", "unknown", "medium", "Review inventory entry"]
    | @tsv
  ' "$inventory"
)

line_number=0
while IFS=$'\t' read -r recommendation command_name uses classification origin installed confidence action; do
  [[ -n "$command_name" ]] || continue
  line_number=$((line_number + 1))
  case "$recommendation" in
    ADD) recommendation='🟢➕ ADD' ;;
    REVIEW) recommendation='🤔 REVIEW' ;;
    KEEP) recommendation='✅ KEEP' ;;
    REMOVE) recommendation='🔴➖ REMOVE' ;;
    IGNORE) recommendation='⏭️ IGNORE' ;;
  esac
  printf '%-3s %-16s %-18s %6s %-16s %-15s %-9s %-10s %s\n' "$line_number" "$recommendation" "$command_name" "$uses" "$classification" "$origin" "$installed" "$confidence" "$action"
done <<<"$rows"

printf '\nNo files, manifests, or installed tools were changed. Apply decisions manually.\n'
