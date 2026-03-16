#!/bin/bash
# Mission Control - Memory Search via QMD
# Usage: mc-memory-search.sh <query> [mode]
# Modes: search (default), vsearch (semantic), query (hybrid+rerank)

QUERY="$1"
MODE="${2:-query}"  # Default to query mode (best quality)

if [ -z "$QUERY" ]; then
    echo "Usage: $0 <query> [mode]"
    echo "Modes: search (keyword), vsearch (semantic), query (hybrid+rerank)"
    exit 1
fi

# Ensure bun is in PATH for qmd
export PATH="$HOME/.bun/bin:$PATH"

# Execute search based on mode
case "$MODE" in
    search)
        RESULTS=$(qmd search "$QUERY" -n 3 2>&1)
        ;;
    vsearch)
        RESULTS=$(qmd vsearch "$QUERY" -n 3 2>&1)
        ;;
    query)
        RESULTS=$(qmd query "$QUERY" -n 3 --min-score 0.3 2>&1)
        ;;
    *)
        echo "Invalid mode: $MODE"
        exit 1
        ;;
esac

# Log search to Mission Control
~/clawd/scripts/mission-control-log.sh \
    "memory_search" \
    "QMD $MODE: '$QUERY' → $(echo "$RESULTS" | wc -l) results" \
    "qmd-integration"

# Output results
echo "$RESULTS"
