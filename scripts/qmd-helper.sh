#!/bin/bash
# QMD Helper - Quick search utilities for memory/workspace

export PATH="$HOME/.bun/bin:$PATH"

# Default to workspace directory
cd ~/clawd 2>/dev/null || true

case "$1" in
  "search"|"s")
    # Fast keyword search
    qmd search "${@:2}"
    ;;
  "vsearch"|"vs")
    # Semantic vector search
    qmd vsearch "${@:2}"
    ;;
  "get"|"g")
    # Get specific file
    qmd get "${@:2}"
    ;;
  "today")
    # Get today's memory
    DATE=$(date +%Y-%m-%d)
    qmd get "memory/$DATE.md" -l 100
    ;;
  "yesterday")
    # Get yesterday's memory
    DATE=$(date -d yesterday +%Y-%m-%d)
    qmd get "memory/$DATE.md" -l 100
    ;;
  "recent")
    # Get recent memory files (last 7 days)
    qmd multi-get "memory/$(date +%Y-%m)-*.md" --json | head -200
    ;;
  "status")
    qmd status
    ;;
  "update")
    qmd update
    ;;
  *)
    echo "QMD Helper - Token-Optimized Memory Search"
    echo ""
    echo "Usage:"
    echo "  qmd-helper search|s <query> [-n N]       Fast keyword search"
    echo "  qmd-helper vsearch|vs <query> [-n N]     Semantic vector search"
    echo "  qmd-helper get|g <file>                  Get specific file"
    echo "  qmd-helper today                         Today's memory (first 100 lines)"
    echo "  qmd-helper yesterday                     Yesterday's memory"
    echo "  qmd-helper recent                        Recent memory files (7 days)"
    echo "  qmd-helper status                        Index status"
    echo "  qmd-helper update                        Re-index collections"
    echo ""
    echo "Examples:"
    echo "  qmd-helper search 'gmail setup' -n 5"
    echo "  qmd-helper vsearch 'how to send emails'"
    echo "  qmd-helper today"
    ;;
esac
