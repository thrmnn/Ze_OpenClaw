#!/bin/bash
# Memory management helper

ACTION=${1:-help}
TODAY=$(date +%Y-%m-%d)
DAILY_FILE="memory/$TODAY.md"

case "$ACTION" in
  new)
    # Create today's daily log if missing
    if [ ! -f "$DAILY_FILE" ]; then
      echo "# $TODAY" > "$DAILY_FILE"
      echo "" >> "$DAILY_FILE"
      echo "✅ Created $DAILY_FILE"
    else
      echo "✅ $DAILY_FILE already exists"
    fi
    ;;
  
  view)
    # View today's log
    cat "$DAILY_FILE" 2>/dev/null || echo "No log for today"
    ;;
  
  recent)
    # Show last 3 days
    for i in {0..2}; do
      DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
      FILE="memory/$DATE.md"
      if [ -f "$FILE" ]; then
        echo "=== $DATE ==="
        head -20 "$FILE"
        echo ""
      fi
    done
    ;;
  
  help)
    echo "Usage: memory-helper.sh [new|view|recent]"
    echo ""
    echo "Commands:"
    echo "  new     - Create today's daily log"
    echo "  view    - View today's log"
    echo "  recent  - Show last 3 days"
    ;;
  
  *)
    echo "Unknown command: $ACTION"
    exit 1
    ;;
esac
