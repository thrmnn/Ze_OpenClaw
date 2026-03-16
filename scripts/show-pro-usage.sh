#!/bin/bash
# Show Claude Pro usage for today

echo "📊 Claude Pro Usage - Today"
echo "=" | head -c 50; echo ""

# Get today's usage from ccusage
TODAY=$(date +%Y-%m-%d)
OUTPUT=$(npx ccusage 2>&1)

# Extract today's data
TODAY_DATA=$(echo "$OUTPUT" | grep -A 1 "$TODAY" | tail -1)

if [ -n "$TODAY_DATA" ]; then
    echo "$TODAY_DATA" | awk '{
        printf "Tokens Today: %s\n", $NF-1
        printf "Cost Today: %s\n\n", $NF
    }'
else
    echo "No usage data for today yet"
    echo ""
fi

# Show weekly total
WEEK_COST=$(echo "$OUTPUT" | grep -E "2026-01-" | awk '{sum += $(NF)} END {printf "%.2f", sum}')
echo "This Week Total: \$$WEEK_COST"
echo ""

# Claude Pro limits (you need to configure these)
echo "⚠️  Claude Pro Limits:"
echo "  Daily: Check claude.ai/settings/limits"
echo "  This script shows usage, not limits"
echo ""
echo "📍 To see limits: https://claude.ai/settings/limits"
