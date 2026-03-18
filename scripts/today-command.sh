#!/bin/bash
# /today command - Process daily notes and synthesize actionable day plan

set -e

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$VAULT_PATH/Daily/$TODAY.md"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📋 Processing daily note for $TODAY...${NC}\n"

# Check if daily note exists
if [[ ! -f "$DAILY_NOTE" ]]; then
    echo "❌ Daily note not found: $DAILY_NOTE"
    exit 1
fi

# Extract raw notes from top of file (before first heading)
RAW_NOTES=$(awk '/^#/{exit} {print}' "$DAILY_NOTE" | grep -v '^$' | head -30)

if [[ -z "$RAW_NOTES" ]]; then
    echo -e "${YELLOW}⚠️  No raw notes found at top of daily note${NC}"
    echo "Add notes before the first # heading for processing"
    exit 0
fi

echo -e "${GREEN}📝 Raw notes extracted:${NC}"
echo "$RAW_NOTES"
echo ""

# Get Trello NOW tasks
echo -e "${BLUE}📋 Fetching Trello NOW tasks...${NC}"
TRELLO_TASKS=$(bash ~/clawd/scripts/trello-synthesis.sh 2>/dev/null | grep -A 20 "NOW tasks:" || echo "")

echo ""
echo -e "${GREEN}✅ Context gathered:${NC}"
echo "- Daily notes extracted"
echo "- Trello NOW tasks fetched"
echo ""
echo -e "${YELLOW}🤖 Ready for Zé to synthesize and propose action plan${NC}"
echo ""
echo "Raw notes:"
echo "$RAW_NOTES"
echo ""
echo "Trello context:"
echo "$TRELLO_TASKS"

