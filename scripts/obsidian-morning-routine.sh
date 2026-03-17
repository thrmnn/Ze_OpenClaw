#!/bin/bash
# Morning routine: Create/update today's daily note in Personal vault
# Auto-pulls: Trello NOW tasks

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault"
TODAY=$(date +%Y-%m-%d)
DAY_NAME=$(date +%A)
DAILY_NOTE="$VAULT_PATH/Daily/$TODAY.md"

echo "🌅 Good morning! Preparing your daily note..."

# Check if daily note exists
if [ -f "$DAILY_NOTE" ]; then
  echo "📝 Daily note already exists for $TODAY"
  exit 0
fi

# Get Trello tasks
echo "📋 Fetching Trello NOW tasks..."
TRELLO_TASKS=$(bash ~/clawd/scripts/trello-synthesis.sh 2>&1 | grep -A 20 "All NOW tasks")

# Create daily note using obsidian.sh
bash ~/clawd/scripts/obsidian.sh --vault personal create "Daily/$TODAY" "# $DAY_NAME, $TODAY

## 🎯 3-3-3 Focus

### 🔴 3 Deep Work (high focus, 2h+ blocks)
1. 
2. 
3. 

### 🟡 3 Maintenance (30-60 min each)
1. 
2. 
3. 

### 🟢 3 Quick Wins (< 15 min each)
1. 
2. 
3. 

---

## 📋 Trello NOW

$TRELLO_TASKS

---

## 📝 Notes



---

## 💡 Decisions



---

## 🔗 Links

- Previous: [[Daily/$(date -d 'yesterday' +%Y-%m-%d)]]

---

**Created by Zé at $(date '+%H:%M')** 😌
"

echo "✅ Daily note created: Daily/$TODAY.md"
