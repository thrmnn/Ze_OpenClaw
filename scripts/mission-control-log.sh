#!/bin/bash
# Mission Control - Log Activity
# Usage: mission-control-log.sh <type> <message> [agentId]

TYPE="$1"
MESSAGE="$2"
AGENT_ID="${3:-}"

if [ -z "$TYPE" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: $0 <type> <message> [agentId]"
    exit 1
fi

MC_URL="https://mission-control-ruby-zeta.vercel.app"

# Build JSON payload
if [ -n "$AGENT_ID" ]; then
    PAYLOAD="{\"type\":\"$TYPE\",\"message\":\"$MESSAGE\",\"agentId\":\"$AGENT_ID\"}"
else
    PAYLOAD="{\"type\":\"$TYPE\",\"message\":\"$MESSAGE\"}"
fi

curl -s -X POST "$MC_URL/api/activity" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
