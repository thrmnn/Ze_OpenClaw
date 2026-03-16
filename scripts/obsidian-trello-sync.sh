#!/bin/bash
# Sync Trello NOW tasks to today's Obsidian daily note

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault"
TODAY=$(date +%Y-%m-%d)
DAILY_NOTE="$VAULT_PATH/Daily/$TODAY.md"

# Get Trello synthesis
TRELLO_OUTPUT=$(bash ~/clawd/scripts/trello-synthesis.sh 2>&1)

# Check if daily note exists
if [ ! -f "$DAILY_NOTE" ]; then
  echo "Creating daily note for $TODAY..."
  bash ~/clawd/scripts/obsidian.sh create "Daily/$TODAY" "# $TODAY

## 🌅 Morning
- [ ] 

## 🌞 Afternoon  
- [ ] 

## 🌙 Evening
- [ ] 

## 📝 Trello Tasks (NOW)
$TRELLO_OUTPUT

## 💡 Decisions


## 🔗 Links
- [[Projects/]]
"
else
  # Check if Trello section exists
  if grep -q "## 📝 Trello Tasks" "$DAILY_NOTE"; then
    echo "Updating Trello section in $TODAY daily note..."
    # Replace Trello section (simple version - can be improved)
    echo "Manual update needed - append mode:"
    echo "$TRELLO_OUTPUT"
  else
    echo "Appending Trello tasks to $TODAY daily note..."
    bash ~/clawd/scripts/obsidian.sh append "Daily/$TODAY" "

## 📝 Trello Tasks (NOW)
$TRELLO_OUTPUT
"
  fi
fi

echo "✅ Trello sync complete"
