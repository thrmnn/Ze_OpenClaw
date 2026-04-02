#!/bin/bash
# Claude Code usage monitoring with prediction
# Uses ccusage to track actual Pro plan usage
set -e

# Pro plan monthly budget (adjust based on your plan)
MONTHLY_BUDGET=${CLAUDE_MONTHLY_BUDGET:-100}

# Get current month usage
USAGE_JSON=$(ccusage monthly --json 2>&1)

# Extract current month data
CURRENT_MONTH=$(date +%Y-%m)
MONTH_DATA=$(echo "$USAGE_JSON" | jq -r --arg month "$CURRENT_MONTH" '.monthly[] | select(.month == $month)')

if [ -z "$MONTH_DATA" ] || [ "$MONTH_DATA" == "null" ]; then
  echo "No usage data for current month yet"
  exit 0
fi

# Extract metrics
TOTAL_COST=$(echo "$MONTH_DATA" | jq -r '.totalCost')
INPUT_TOKENS=$(echo "$MONTH_DATA" | jq -r '.inputTokens')
OUTPUT_TOKENS=$(echo "$MONTH_DATA" | jq -r '.outputTokens')
CACHE_READ=$(echo "$MONTH_DATA" | jq -r '.cacheReadTokens')
CACHE_WRITE=$(echo "$MONTH_DATA" | jq -r '.cacheCreationTokens')

# Calculate metrics
DAY_OF_MONTH=$(date +%-d)
DAYS_IN_MONTH=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%-d)
DAYS_REMAINING=$((DAYS_IN_MONTH - DAY_OF_MONTH))

# Daily burn rate
DAILY_RATE=$(echo "scale=2; $TOTAL_COST / $DAY_OF_MONTH" | bc)

# Projected end-of-month cost
PROJECTED_COST=$(echo "scale=2; $DAILY_RATE * $DAYS_IN_MONTH" | bc)

# Budget percentage
BUDGET_USED_PCT=$(echo "scale=1; ($TOTAL_COST / $MONTHLY_BUDGET) * 100" | bc)
PROJECTED_PCT=$(echo "scale=1; ($PROJECTED_COST / $MONTHLY_BUDGET) * 100" | bc)

# Status indicator
if (( $(echo "$PROJECTED_PCT < 70" | bc -l) )); then
  STATUS="🟢 GOOD"
elif (( $(echo "$PROJECTED_PCT < 85" | bc -l) )); then
  STATUS="🟡 WATCH"
elif (( $(echo "$PROJECTED_PCT < 95" | bc -l) )); then
  STATUS="🟠 CAUTION"
else
  STATUS="🔴 ALERT"
fi

# Output format
if [ "$1" == "--json" ]; then
  cat << EOF
{
  "month": "$CURRENT_MONTH",
  "currentCost": $TOTAL_COST,
  "monthlyBudget": $MONTHLY_BUDGET,
  "budgetUsedPct": $BUDGET_USED_PCT,
  "dailyRate": $DAILY_RATE,
  "projectedCost": $PROJECTED_COST,
  "projectedPct": $PROJECTED_PCT,
  "dayOfMonth": $DAY_OF_MONTH,
  "daysInMonth": $DAYS_IN_MONTH,
  "daysRemaining": $DAYS_REMAINING,
  "status": "$STATUS",
  "tokens": {
    "input": $INPUT_TOKENS,
    "output": $OUTPUT_TOKENS,
    "cacheRead": $CACHE_READ,
    "cacheWrite": $CACHE_WRITE
  }
}
EOF
else
  cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Claude Code Usage Report - $CURRENT_MONTH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Current Usage:
   Cost: \$$TOTAL_COST / \$$MONTHLY_BUDGET ($BUDGET_USED_PCT%)
   Day: $DAY_OF_MONTH / $DAYS_IN_MONTH ($DAYS_REMAINING days left)

📈 Burn Rate:
   Daily: \$$DAILY_RATE
   Projected EOM: \$$PROJECTED_COST ($PROJECTED_PCT%)

🎯 Status: $STATUS

💾 Tokens:
   Input:       $(numfmt --grouping $INPUT_TOKENS)
   Output:      $(numfmt --grouping $OUTPUT_TOKENS)
   Cache Read:  $(numfmt --grouping $CACHE_READ)
   Cache Write: $(numfmt --grouping $CACHE_WRITE)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi
