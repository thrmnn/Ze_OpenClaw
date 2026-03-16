#!/bin/bash
# Mission Control Integration Test Script

set -e

MC_URL="https://mission-control-ruby-zeta.vercel.app"

echo "🧪 Mission Control Integration Test"
echo "===================================="
echo ""

# Test 1: Log Activity
echo "Test 1: Logging activity..."
ACTIVITY_RESULT=$(curl -s -X POST "$MC_URL/api/activity" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "test",
    "agentId": "dev-001",
    "message": "Test activity from Zé via Telegram",
    "metadata": {
      "source": "telegram",
      "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    }
  }')

echo "$ACTIVITY_RESULT" | jq '.'
echo ""

# Test 2: Update Agent Status
echo "Test 2: Updating agent status..."
STATUS_RESULT=$(curl -s -X POST "$MC_URL/api/agent-update-direct" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "dev-001",
    "status": "working",
    "currentTask": "Testing Mission Control integration from Telegram"
  }')

echo "$STATUS_RESULT" | jq '.'
echo ""

# Wait a bit
echo "⏳ Waiting 3 seconds..."
sleep 3
echo ""

# Test 3: Create Spawn Request
echo "Test 3: Creating spawn request..."
SPAWN_RESULT=$(curl -s -X POST "$MC_URL/api/spawn-request" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "research-001",
    "agentName": "Morpheus",
    "task": "Research Mission Control integration patterns",
    "reason": "Testing spawn request from Telegram"
  }')

echo "$SPAWN_RESULT" | jq '.'
REQUEST_ID=$(echo "$SPAWN_RESULT" | jq -r '.requestId')
echo ""

# Test 4: Set Agent Back to Idle
echo "Test 4: Setting agent back to idle..."
IDLE_RESULT=$(curl -s -X POST "$MC_URL/api/agent-update-direct" \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "dev-001",
    "status": "idle",
    "currentTask": null
  }')

echo "$IDLE_RESULT" | jq '.'
echo ""

# Test 5: Fetch Recent Activity
echo "Test 5: Fetching recent activity..."
FETCH_RESULT=$(curl -s "$MC_URL/api/activity?limit=5")
echo "$FETCH_RESULT" | jq '.activities | length' | xargs echo "Activity count:"
echo ""

echo "✅ All tests completed!"
echo ""
echo "📊 Results Summary:"
echo "  - Activity logged: $(echo "$ACTIVITY_RESULT" | jq -r '.success')"
echo "  - Agent status updated: $(echo "$STATUS_RESULT" | jq -r '.success')"
echo "  - Spawn request created: $REQUEST_ID"
echo "  - Agent returned to idle: $(echo "$IDLE_RESULT" | jq -r '.success')"
echo ""
echo "🎯 Next: Check Mission Control dashboard for updates!"
echo "   URL: $MC_URL"
