#!/bin/bash
# mc-agent-report.sh — Report agent status to Mission Control
#
# Usage:
#   mc-agent-report.sh start   "Agent Name" "task description"
#   mc-agent-report.sh progress "Agent Name" "milestone message"
#   mc-agent-report.sh done    "Agent Name" "completion summary"
#   mc-agent-report.sh error   "Agent Name" "error message"
#
# Options:
#   --verbose   Show curl output

set -euo pipefail

MC_URL="https://mission-control-ruby-zeta.vercel.app/api/agent-update-direct"

VERBOSE=false
for arg in "$@"; do
  if [[ "$arg" == "--verbose" ]]; then
    VERBOSE=true
  fi
done

# Strip --verbose from positional args
ARGS=()
for arg in "$@"; do
  [[ "$arg" != "--verbose" ]] && ARGS+=("$arg")
done

ACTION="${ARGS[0]:-}"
NAME="${ARGS[1]:-}"
MSG="${ARGS[2]:-}"

if [[ -z "$ACTION" || -z "$NAME" ]]; then
  echo "Usage: mc-agent-report.sh <start|progress|done|error> \"Agent Name\" \"message\""
  exit 1
fi

# Derive agentId from name: lowercase, spaces to hyphens
AGENT_ID=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')

# Map action to API status
case "$ACTION" in
  start)
    STATUS="working"
    CURRENT_TASK="$MSG"
    STATS=""
    ;;
  progress)
    STATUS="working"
    CURRENT_TASK="$MSG"
    STATS=""
    ;;
  done)
    STATUS="idle"
    CURRENT_TASK="$MSG"
    STATS=', "stats": {"completionTime": 0, "success": true}'
    ;;
  error)
    STATUS="error"
    CURRENT_TASK="$MSG"
    STATS=""
    ;;
  *)
    echo "Unknown action: $ACTION (use start|progress|done|error)"
    exit 1
    ;;
esac

# Build JSON payload — use jq if available for safe escaping, else manual
if command -v jq &>/dev/null; then
  PAYLOAD=$(jq -n \
    --arg agentId "$AGENT_ID" \
    --arg status "$STATUS" \
    --arg currentTask "$CURRENT_TASK" \
    '{agentId: $agentId, status: $status, currentTask: $currentTask}')
  if [[ -n "$STATS" ]]; then
    PAYLOAD=$(echo "$PAYLOAD" | jq '. + {stats: {completionTime: 0, success: true}}')
  fi
else
  PAYLOAD="{\"agentId\":\"$AGENT_ID\",\"status\":\"$STATUS\",\"currentTask\":\"$CURRENT_TASK\"$STATS}"
fi

CURL_OPTS=(-s -X POST "$MC_URL" -H "Content-Type: application/json" -d "$PAYLOAD")

if [[ "$VERBOSE" == "true" ]]; then
  echo "POST $MC_URL"
  echo "$PAYLOAD" | jq . 2>/dev/null || echo "$PAYLOAD"
  RESULT=$(curl "${CURL_OPTS[@]}")
  echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
else
  curl "${CURL_OPTS[@]}" -o /dev/null
fi
