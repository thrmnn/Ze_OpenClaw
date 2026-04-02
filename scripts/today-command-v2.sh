#!/bin/bash
# /today command - v2 - Obsidian-first productivity system

set -e

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault"
PROJECTS_PATH="$VAULT_PATH/Projects"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$VAULT_PATH/Daily/$TODAY.md"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📋 /today - Processing daily workflow...${NC}\n"

# Step 1: Extract tasks from today's daily note
echo -e "${GREEN}1️⃣ Reading today's daily note${NC}"
if [[ ! -f "$DAILY_NOTE" ]]; then
    echo "❌ Daily note not found: $DAILY_NOTE"
    exit 1
fi

# Extract incomplete tasks from daily note
DAILY_TASKS=$(grep -E '^\s*- \[ \]' "$DAILY_NOTE" 2>/dev/null || echo "")
DAILY_COUNT=$(echo "$DAILY_TASKS" | grep -c '- \[ \]' || echo "0")
echo "  Found $DAILY_COUNT tasks in daily note"

# Step 2: Scan all project folders for tasks.md
echo -e "\n${GREEN}2️⃣ Scanning project folders${NC}"
PROJECT_NEXT_ACTIONS=()

if [[ -d "$PROJECTS_PATH" ]]; then
    find "$PROJECTS_PATH" -mindepth 2 -maxdepth 2 -name "tasks.md" | while read TASKS_FILE; do
        PROJECT_DIR=$(dirname "$TASKS_FILE")
        PROJECT_NAME=$(basename "$PROJECT_DIR")
        
        # Find first incomplete task
        NEXT_ACTION=$(grep -m 1 -E '^\s*- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$NEXT_ACTION" ]]; then
            echo "  ✓ $PROJECT_NAME: $(echo "$NEXT_ACTION" | sed 's/^[[:space:]]*- \[ \] //')"
            echo "$PROJECT_NAME|$NEXT_ACTION|$TASKS_FILE" >> /tmp/project_next_actions.txt
        fi
    done
fi

# Step 3: Extract yesterday's unfinished tasks
echo -e "\n${GREEN}3️⃣ Checking yesterday's unfinished tasks${NC}"
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
YESTERDAY_NOTE="$VAULT_PATH/Daily/$YESTERDAY.md"
YESTERDAY_TASKS=""

if [[ -f "$YESTERDAY_NOTE" ]]; then
    YESTERDAY_TASKS=$(grep -E '^\s*- \[ \]' "$YESTERDAY_NOTE" 2>/dev/null || echo "")
    YESTERDAY_COUNT=$(echo "$YESTERDAY_TASKS" | grep -c '- \[ \]' || echo "0")
    echo "  Found $YESTERDAY_COUNT unfinished from yesterday"
fi

# Step 4: Output for Zé to prioritize
echo -e "\n${YELLOW}📊 Task Inventory:${NC}"
echo -e "\n${BLUE}From Today's Daily Note:${NC}"
echo "$DAILY_TASKS"

echo -e "\n${BLUE}From Project Next Actions:${NC}"
if [[ -f /tmp/project_next_actions.txt ]]; then
    cat /tmp/project_next_actions.txt | while IFS='|' read PROJECT TASK FILE; do
        echo "  [$PROJECT] $(echo "$TASK" | sed 's/^[[:space:]]*- \[ \] //')"
    done
    rm /tmp/project_next_actions.txt
fi

echo -e "\n${BLUE}From Yesterday (Unfinished):${NC}"
echo "$YESTERDAY_TASKS"

echo -e "\n${YELLOW}🤖 Ready for Zé to prioritize and update Trello${NC}"
