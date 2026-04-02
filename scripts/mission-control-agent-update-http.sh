#!/bin/bash
# Mission Control - Update Agent Status via HTTP API
# Usage: mission-control-agent-update-http.sh <agentId> <status> [currentTask]
# Uses the working /api/agent-update-direct endpoint

AGENT_ID="$1"
STATUS="$2"
CURRENT_TASK="${3:-}"

if [ -z "$AGENT_ID" ] || [ -z "$STATUS" ]; then
    echo "Usage: $0 <agentId> <status> [currentTask]"
    echo "Status: idle | working | error | offline"
    exit 1
fi

MC_URL="https://mission-control-ruby-zeta.vercel.app"

# Build JSON payload
if [ -n "$CURRENT_TASK" ]; then
    JSON_DATA=$(cat <<EOF
{
  "agentId": "$AGENT_ID",
  "status": "$STATUS",
  "currentTask": "$CURRENT_TASK"
}
EOF
)
else
    JSON_DATA=$(cat <<EOF
{
  "agentId": "$AGENT_ID",
  "status": "$STATUS"
}
EOF
)
fi

# Call the working endpoint
RESULT=$(curl -s -X POST "$MC_URL/api/agent-update-direct" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

# Check if successful
if echo "$RESULT" | jq -e '.success == true' > /dev/null 2>&1; then
    echo "✅ Agent $AGENT_ID updated to status: $STATUS"
    [ -n "$CURRENT_TASK" ] && echo "   Task: $CURRENT_TASK"
    echo "$RESULT" | jq '.'
else
    echo "❌ Failed to update agent $AGENT_ID"
    echo "$RESULT" | jq '.'
    exit 1
fi
