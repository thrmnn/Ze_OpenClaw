#!/bin/bash
# Morning Brief - sends via Clawdbot to Telegram

DATE=$(date +"%A, %B %d, %Y")
QUOTE=$(jq -r '.[] | "\(.text)||||\(.author)"' /home/theo/clawd/data/quotes.json | shuf -n 1)
QUOTE_TEXT=$(echo "$QUOTE" | cut -d'|' -f1)
QUOTE_AUTHOR=$(echo "$QUOTE" | cut -d'|' -f5)

# Get Trello synthesis
TRELLO_SYNTHESIS=$(bash /home/theo/clawd/scripts/trello-synthesis.sh 2>/dev/null)
TASK_COUNT=$(echo "$TRELLO_SYNTHESIS" | grep "Total tasks" | grep -oP '\d+' || echo "0")
TASKS=$(echo "$TRELLO_SYNTHESIS" | sed -n '/📝 All NOW tasks:/,/^$/p' | grep "•" | head -5)

# Get AI updates from X
cd /home/theo/clawd
source venv-google/bin/activate 2>/dev/null
AI_UPDATES=$(python3 scripts/fetch-x-voices.py 2>/dev/null || echo "• AI monitoring ready (awaiting voices list)")

# Simple news (placeholder - can add RSS later)
NEWS="• AI developments continue to accelerate
• Tech sector shows positive momentum  
• Focus on productivity and efficiency"

# Build message
MESSAGE="☀️ Good morning Théo!

📅 $DATE

🤖 AI Field Updates:
$AI_UPDATES

💭 Today's thought:
\"$QUOTE_TEXT\" 
— $QUOTE_AUTHOR

📋 Your tasks today ($TASK_COUNT in NOW):
$TASKS

📰 In brief:
$NEWS

Have a productive day! 😌"

# Send via Clawdbot
echo "$MESSAGE"
