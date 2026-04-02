#!/bin/bash
# Morning routine: Create today's daily note with pre-filled 3-3-3
# Pulls: Trello NOW tasks + reads all project tasks.md files to prioritize
# Sends Telegram notification after creation

BASE="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults"
PERSONAL="$BASE/Ob_Perso_Vault"
TODAY=$(date +%Y-%m-%d)
DAY_NAME=$(date +%A)
DAILY_NOTE="$PERSONAL/Daily/$TODAY.md"

echo "🌅 Good morning! Preparing your daily note..."

if [ -f "$DAILY_NOTE" ]; then
  echo "📝 Daily note already exists for $TODAY"
  exit 0
fi

# Gather Trello tasks
echo "📋 Fetching Trello NOW tasks..."
TRELLO_TASKS=$(bash ~/clawd/scripts/trello-synthesis.sh 2>&1 | grep -A 20 "All NOW tasks")

# Gather all project tasks across vaults
echo "📂 Scanning project tasks..."
TASK_CONTEXT=""
for vault_dir in "$BASE"/Ob_*; do
  vault_name=$(basename "$vault_dir")
  while IFS= read -r tasks_file; do
    project=$(echo "$tasks_file" | sed "s|$vault_dir/||" | sed 's|/tasks.md||')
    # Get NOW/urgent section (first 15 lines of actionable tasks)
    urgent=$(grep -A 15 "NOW\|URGENT\|Next Actions\|Priority 1" "$tasks_file" 2>/dev/null | grep "^\- \[ \]" | head -5)
    if [ -n "$urgent" ]; then
      TASK_CONTEXT="$TASK_CONTEXT
### $project ($vault_name)
$urgent
"
    fi
  done < <(find "$vault_dir" -name "tasks.md" -not -path "*/.obsidian/*" -not -path "*/Templates/*" 2>/dev/null)
done

# Create daily note
mkdir -p "$PERSONAL/Daily"
cat > "$DAILY_NOTE" << HEREDOC
# $DAY_NAME, $TODAY

## 🎯 3-3-3 Focus

> Pre-filled by Zé based on project deadlines and priorities.
> Edit freely — this is YOUR plan for the day.

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

## 📋 Active Tasks (from all projects)

$TASK_CONTEXT

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
HEREDOC

echo "✅ Daily note created: Daily/$TODAY.md"
