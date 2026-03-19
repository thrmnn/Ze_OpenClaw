#!/bin/bash
# Track current session usage (Pro plan limits)
# Reads from Claude Code's current session stats

# Pro plan limits (adjust based on actual limits)
SESSION_TOKEN_LIMIT=${SESSION_TOKEN_LIMIT:-200000}

# Get current session stats from ccusage
CURRENT_SESSION=$(ccusage session --json | jq -r '.sessions | sort_by(.lastActivity) | reverse | .[0]')

if [ -z "$CURRENT_SESSION" ] || [ "$CURRENT_SESSION" == "null" ]; then
  echo "⚠️  No active session data available"
  exit 0
fi

# Extract tokens
INPUT_TOKENS=$(echo "$CURRENT_SESSION" | jq -r '.inputTokens')
OUTPUT_TOKENS=$(echo "$CURRENT_SESSION" | jq -r '.outputTokens')
CACHE_READ=$(echo "$CURRENT_SESSION" | jq -r '.cacheReadTokens')
CACHE_WRITE=$(echo "$CURRENT_SESSION" | jq -r '.cacheCreationTokens')
TOTAL_TOKENS=$(echo "$CURRENT_SESSION" | jq -r '.totalTokens')
SESSION_ID=$(echo "$CURRENT_SESSION" | jq -r '.sessionId')
LAST_ACTIVITY=$(echo "$CURRENT_SESSION" | jq -r '.lastActivity')

# Calculate percentage used
USED_PCT=$(echo "scale=1; ($TOTAL_TOKENS / $SESSION_TOKEN_LIMIT) * 100" | bc)
REMAINING_PCT=$(echo "scale=1; 100 - $USED_PCT" | bc)
REMAINING_TOKENS=$((SESSION_TOKEN_LIMIT - TOTAL_TOKENS))

# Status indicator
if (( $(echo "$USED_PCT < 50" | bc -l) )); then
  STATUS="🟢 PLENTY"
elif (( $(echo "$USED_PCT < 75" | bc -l) )); then
  STATUS="🟡 MODERATE"
elif (( $(echo "$USED_PCT < 90" | bc -l) )); then
  STATUS="🟠 RUNNING LOW"
else
  STATUS="🔴 NEAR LIMIT"
fi

# Output
if [ "$1" == "--json" ]; then
  cat << EOF
{
  "sessionId": "$SESSION_ID",
  "lastActivity": "$LAST_ACTIVITY",
  "totalTokens": $TOTAL_TOKENS,
  "sessionLimit": $SESSION_TOKEN_LIMIT,
  "usedPct": $USED_PCT,
  "remainingPct": $REMAINING_PCT,
  "remainingTokens": $REMAINING_TOKENS,
  "status": "$STATUS",
  "breakdown": {
    "input": $INPUT_TOKENS,
    "output": $OUTPUT_TOKENS,
    "cacheRead": $CACHE_READ,
    "cacheWrite": $CACHE_WRITE
  }
}
EOF
else
  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Session Usage - Pro Plan
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Session: $SESSION_ID
   Last: $LAST_ACTIVITY

💾 Tokens Used:
   $(numfmt --grouping $TOTAL_TOKENS) / $(numfmt --grouping $SESSION_TOKEN_LIMIT) ($USED_PCT%)
   
📈 Remaining:
   $(numfmt --grouping $REMAINING_TOKENS) tokens ($REMAINING_PCT%)

🎯 Status: $STATUS

🔍 Breakdown:
   Input:       $(numfmt --grouping $INPUT_TOKENS)
   Output:      $(numfmt --grouping $OUTPUT_TOKENS)
   Cache Read:  $(numfmt --grouping $CACHE_READ)
   Cache Write: $(numfmt --grouping $CACHE_WRITE)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi
