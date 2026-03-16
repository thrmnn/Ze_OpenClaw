#!/bin/bash
# Mission Control - Create Spawn Request
# Usage: mission-control-spawn.sh <agentId> <agentName> <task> <reason>

AGENT_ID="$1"
AGENT_NAME="$2"
TASK="$3"
REASON="$4"

if [ -z "$AGENT_ID" ] || [ -z "$AGENT_NAME" ] || [ -z "$TASK" ] || [ -z "$REASON" ]; then
    echo "Usage: $0 <agentId> <agentName> <task> <reason>"
    exit 1
fi

cd ~/clawd/mission-control

CONVEX_DEPLOYMENT=prod:usable-whale-844 npx convex run spawnRequests:createSpawnRequest \
  "{\"agentId\":\"$AGENT_ID\",\"agentName\":\"$AGENT_NAME\",\"task\":\"$TASK\",\"reason\":\"$REASON\"}"
