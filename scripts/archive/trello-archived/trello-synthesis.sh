#!/bin/bash
# Trello Task Synthesis - Quick overview of NOW tasks

set -e

# Load credentials
source ~/clawd/credentials/trello.env

BOARD_ID="699dc91ad27a2301f3acc5f1"  # Zé Dashboard
NOW_LIST_ID="699dc91ad27a2301f3acc5e5"  # Current Sprint

echo "📋 Trello Task Synthesis"
echo "========================"
echo ""

# Get cards with full details
CARDS=$(curl -s "https://api.trello.com/1/lists/${NOW_LIST_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}&fields=name,desc,due,dueComplete,badges&checklists=all")

# Count total cards
TOTAL=$(echo "$CARDS" | jq '. | length')
echo "📊 Total tasks in NOW: $TOTAL"
echo ""

# Count tasks with due dates
DUE_COUNT=$(echo "$CARDS" | jq '[.[] | select(.due != null)] | length')
if [ "$DUE_COUNT" -gt 0 ]; then
    echo "⏰ Tasks with due dates: $DUE_COUNT"
    echo "$CARDS" | jq -r '.[] | select(.due != null) | "  • \(.name) → Due: \(.due[0:10])"'
    echo ""
fi

# Count tasks with checklists
CHECKLIST_CARDS=$(echo "$CARDS" | jq '[.[] | select(.badges.checkItems > 0)] | length')
if [ "$CHECKLIST_CARDS" -gt 0 ]; then
    echo "✅ Tasks with checklists: $CHECKLIST_CARDS"
    echo "$CARDS" | jq -r '.[] | select(.badges.checkItems > 0) | "  • \(.name) → \(.badges.checkItemsChecked)/\(.badges.checkItems) done"'
    echo ""
fi

# List all tasks (grouped by priority if needed)
echo "📝 All NOW tasks:"
echo "$CARDS" | jq -r '.[] | "  • \(.name)"'
echo ""

# Summary recommendations
echo "💡 Quick insights:"

# Check for overdue tasks
OVERDUE=$(echo "$CARDS" | jq -r --arg TODAY "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)" '[.[] | select(.due != null and .due < $TODAY and .dueComplete == false)] | length')
if [ "$OVERDUE" -gt 0 ]; then
    echo "  ⚠️  $OVERDUE overdue task(s)"
fi

# Check for tasks without descriptions
NO_DESC=$(echo "$CARDS" | jq '[.[] | select(.desc == "" or .desc == null)] | length')
if [ "$NO_DESC" -gt 0 ]; then
    echo "  📄 $NO_DESC task(s) missing descriptions"
fi

# Check for tasks without due dates
NO_DUE=$(echo "$CARDS" | jq '[.[] | select(.due == null)] | length')
if [ "$NO_DUE" -gt 0 ]; then
    echo "  📅 $NO_DUE task(s) without due dates"
fi

echo ""
echo "🔗 Board: https://trello.com/b/699dc91ad27a2301f3acc5f1"
