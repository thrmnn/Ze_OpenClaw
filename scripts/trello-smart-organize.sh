#!/bin/bash
# Smart Trello organization - Clean up and properly categorize tasks

set -e
source ~/clawd/credentials/trello.env

API_KEY="$TRELLO_API_KEY"
TOKEN="$TRELLO_API_TOKEN"
BOARD_ID="$TRELLO_BOARD_ID"

echo "🧹 Analyzing Trello board for cleanup and organization..."
echo ""

# Get all cards from the board
ALL_CARDS=$(curl -s "https://api.trello.com/1/boards/${BOARD_ID}/cards?key=${API_KEY}&token=${TOKEN}")

# Show current state
echo "📊 Current board state:"
TOTAL_CARDS=$(echo "$ALL_CARDS" | jq '. | length')
echo "Total cards: $TOTAL_CARDS"
echo ""

# List all cards with their lists
echo "📋 All cards by list:"
echo "$ALL_CARDS" | jq -r 'group_by(.idList) | .[] | "\n  List: \(.[0].idList)\n" + (.[] | "    • \(.name)")' 2>/dev/null || echo "$ALL_CARDS" | jq -r '.[] | "  • \(.name) (List: \(.idList))"'

echo ""
echo "---"
echo "Ready to reorganize. Tasks to perform:"
echo "1. Delete duplicate cards"
echo "2. Move quick wins to appropriate list (not Sprint)"
echo "3. Consolidate similar tasks"
echo "4. Add proper descriptions and checklists"
echo "5. Prioritize what goes in Sprint vs Backlog/Upcoming"
echo ""
echo "This is a dry-run. Review and confirm actions needed."
