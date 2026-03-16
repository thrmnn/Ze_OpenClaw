#!/bin/bash
# Test Obsidian Local REST API connection
set -e

API_KEY="92aa35777ef5ea51b4c18cc3f137a0ba848f3ed0ec6f370dc805f28db8149f54"
PORT=27123

echo "Testing Obsidian Local REST API..."
echo

# Check if port is listening
if ! netstat -tuln 2>/dev/null | grep -q $PORT && ! ss -tuln 2>/dev/null | grep -q $PORT; then
  echo "❌ Obsidian not running - port $PORT not listening"
  echo
  echo "To fix:"
  echo "1. Start Obsidian"
  echo "2. Enable Community Plugins → Local REST API"
  echo "3. Check plugin settings for port (should be $PORT)"
  echo "4. Re-run this test"
  exit 1
fi

echo "✅ Port $PORT is listening"
echo

# Test API connection
echo "Testing API authentication..."
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:$PORT/ -H "Authorization: Bearer $API_KEY")
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ Authentication successful"
  echo
  echo "API Response:"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
  echo
  echo "✅ Obsidian MCP is ready to use!"
else
  echo "❌ Authentication failed (HTTP $HTTP_CODE)"
  echo "Response: $BODY"
  echo
  echo "Check:"
  echo "1. API key is correct in plugin settings"
  echo "2. Plugin is enabled and running"
  exit 1
fi
