#!/bin/bash
# Morning routine: Create/update today's daily note
# Auto-pulls: Calendar events + Trello NOW tasks

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault"
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

# Create daily note
bash ~/clawd/scripts/obsidian.sh create "Daily/$TODAY" "# $DAY_NAME, $TODAY

## 🌅 Morning

- [ ] Check emails
- [ ] Review Trello NOW
- [ ] 

## 🌞 Afternoon

- [ ] 
- [ ] 

## 🌙 Evening

- [ ] Plan tomorrow
- [ ] End-of-day reflection

---

## 📋 Trello Tasks (NOW)

$TRELLO_TASKS

---

## 📅 Calendar Events

[Auto-pull pending - OAuth needs refresh]

---

## 📝 Notes



---

## 💡 Decisions



---

## 🔗 Links

- [[Projects/]]
- [[Areas/]]
- Previous: [[Daily/$(date -d 'yesterday' +%Y-%m-%d)]]

---

**Created by Zé at $(date '+%H:%M')** 😌
"

echo "✅ Daily note created: Daily/$TODAY.md"
