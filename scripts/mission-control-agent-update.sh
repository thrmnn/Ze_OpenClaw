#!/bin/bash
# Mission Control - Update Agent Status
# Usage: mission-control-agent-update.sh <agentId> <status> [currentTask]

AGENT_ID="$1"
STATUS="$2"
CURRENT_TASK="${3:-}"

if [ -z "$AGENT_ID" ] || [ -z "$STATUS" ]; then
    echo "Usage: $0 <agentId> <status> [currentTask]"
    echo "Status: idle | working | error | offline"
    exit 1
fi

cd ~/clawd/mission-control

if [ -n "$CURRENT_TASK" ]; then
    CONVEX_DEPLOYMENT=prod:usable-whale-844 npx convex run agents:updateAgentStatus \
      "{\"agentId\":\"$AGENT_ID\",\"status\":\"$STATUS\",\"currentTask\":\"$CURRENT_TASK\"}"
else
    CONVEX_DEPLOYMENT=prod:usable-whale-844 npx convex run agents:updateAgentStatus \
      "{\"agentId\":\"$AGENT_ID\",\"status\":\"$STATUS\"}"
fi
