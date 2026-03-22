#!/bin/bash
# sync-active-agents.sh — Sync running OpenClaw sessions to Mission Control
#
# Runs every 2 minutes via cron. For each active session:
#   - Reports "working" with session key + uptime
# For recently finished sessions:
#   - Reports "idle" (done)
#
# Uses mc-agent-report.sh to POST to Mission Control.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MC_REPORT="$SCRIPT_DIR/mc-agent-report.sh"
STATE_FILE="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/mc-sync-state.json"

# Active = updated in last 5 minutes
ACTIVE_WINDOW=5

# Get all sessions via openclaw status (--all-agents --active flags don't exist)
# Fall back to empty set — MC sync is best-effort
SESSIONS=$(timeout 8 openclaw sessions list --json 2>/dev/null || echo '{"sessions":[]}')

# Parse sessions and report to MC
echo "$SESSIONS" | jq -r '.sessions[] | @base64' 2>/dev/null | while read -r encoded; do
  SESSION=$(echo "$encoded" | base64 -d)

  KEY=$(echo "$SESSION" | jq -r '.key')
  AGENT_ID=$(echo "$SESSION" | jq -r '.agentId // "unknown"')
  AGE_MS=$(echo "$SESSION" | jq -r '.ageMs // 0')
  TOKENS=$(echo "$SESSION" | jq -r '.totalTokens // 0')
  MODEL=$(echo "$SESSION" | jq -r '.model // "unknown"')

  # Skip cron run aliases (duplicates of the parent cron session)
  if [[ "$KEY" == *":run:"* ]]; then
    continue
  fi

  # Derive a human-readable name from the session key
  # agent:main:tui-xxx → "Main TUI Session"
  # agent:main:main → "Main Session"
  # agent:main:cron:xxx → "Main Cron Job"
  case "$KEY" in
    *:tui-*)    NAME="${AGENT_ID^} TUI Session" ;;
    *:cron:*)   NAME="${AGENT_ID^} Cron Job" ;;
    *:main)     NAME="${AGENT_ID^} Session" ;;
    *)          NAME="${AGENT_ID^} Agent" ;;
  esac

  # Calculate uptime
  AGE_MIN=$(( AGE_MS / 60000 ))
  if (( AGE_MIN < 1 )); then
    UPTIME="<1m"
  elif (( AGE_MIN < 60 )); then
    UPTIME="${AGE_MIN}m"
  else
    UPTIME="$((AGE_MIN / 60))h$((AGE_MIN % 60))m"
  fi

  timeout 5 "$MC_REPORT" progress "$NAME" "Active ${UPTIME} | ${TOKENS} tokens | ${MODEL}" 2>/dev/null || true
done

# Check for sessions that were previously active but are now gone
# Compare with saved state
if [[ -f "$STATE_FILE" ]]; then
  PREV_KEYS=$(jq -r '.[]' "$STATE_FILE" 2>/dev/null || true)
  CURR_KEYS=$(echo "$SESSIONS" | jq -r '.sessions[].key' 2>/dev/null || true)

  for prev_key in $PREV_KEYS; do
    if ! echo "$CURR_KEYS" | grep -qF "$prev_key"; then
      # Session is gone — derive name and mark done
      case "$prev_key" in
        *:tui-*)    NAME="Main TUI Session" ;;
        *:cron:*)   NAME="Main Cron Job" ;;
        *:main)     NAME="Main Session" ;;
        *)          NAME="Agent Session" ;;
      esac
      timeout 5 "$MC_REPORT" done "$NAME" "Session ended" 2>/dev/null || true
    fi
  done
fi

# Save current active keys for next run comparison
echo "$SESSIONS" | jq '[.sessions[].key]' > "$STATE_FILE" 2>/dev/null || true

# Also push git status for all projects (if script exists)
if [[ -x "$SCRIPT_DIR/push-git-status.sh" ]]; then
  timeout 10 "$SCRIPT_DIR/push-git-status.sh" 2>/dev/null || true
fi
