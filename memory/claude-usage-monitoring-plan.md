# Claude Pro Usage Monitoring Plan

## Problem
- **Plan:** Claude Pro (paid subscription)
- **Constraints:** Usage limits on API calls, token consumption
- **Risk:** Hitting limits without warning, potential service interruption
- **Need:** Track usage, alert before hitting limits, optimize consumption

---

## Claude Pro Limits (Need to Verify)

**Typical Pro Plan constraints:**
- API requests per day/hour
- Total tokens per day (input + output)
- Context window limits
- Model-specific quotas (Sonnet vs Opus)

**Action:** Check your actual limits at https://console.anthropic.com/settings/limits

---

## Monitoring Strategy

### 1. **Built-in Tracking** (Claude Code)

Claude Code already tracks usage via `/status` command:

```bash
# Shows current session usage
/status

# Response includes:
# - Total tokens (input/output)
# - Cost estimates
# - Session duration
# - Model usage breakdown
```

**Implementation:**
- Use `session_status` tool programmatically
- Store results in `memory/usage-logs/`
- Track trends over time

### 2. **Custom Logging System**

**Location:** `/home/theo/clawd/memory/usage-logs/YYYY-MM-DD.json`

**Schema:**
```json
{
  "date": "2026-01-27",
  "sessions": [
    {
      "timestamp": "2026-01-27T17:30:00Z",
      "model": "claude-sonnet-4-5",
      "inputTokens": 10000,
      "outputTokens": 2000,
      "costUSD": 0.12,
      "sessionDuration": 1800
    }
  ],
  "daily_totals": {
    "inputTokens": 50000,
    "outputTokens": 15000,
    "costUSD": 0.85,
    "sessionsCount": 5
  },
  "alerts": []
}
```

### 3. **Alert Thresholds**

**Warning Levels:**

| Level | Daily Tokens | Daily Cost | Action |
|-------|-------------|------------|--------|
| **Green** | < 70% limit | < 70% budget | Normal operation |
| **Yellow** | 70-85% limit | 70-85% budget | Notify user |
| **Orange** | 85-95% limit | 85-95% budget | Strong warning + suggest optimization |
| **Red** | > 95% limit | > 95% budget | Critical alert, consider pausing non-urgent tasks |

**Example Thresholds (adjust based on your actual limits):**
```javascript
const THRESHOLDS = {
  dailyTokenLimit: 1000000,  // Example: 1M tokens/day
  dailyBudget: 10.00,        // Example: $10/day
  warningAt: 0.70,           // 70%
  criticalAt: 0.95           // 95%
}
```

---

## Implementation Components

### 1. **Usage Logger Script**

**Location:** `/home/theo/clawd/scripts/log-usage.sh`

```bash
#!/bin/bash
# Log Claude usage to daily file

DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date -Iseconds)
LOG_DIR="/home/theo/clawd/memory/usage-logs"
LOG_FILE="$LOG_DIR/$DATE.json"

mkdir -p "$LOG_DIR"

# Get usage from Claude Code session_status
# (This would need to be adapted to actually query session_status)
USAGE=$(echo '{"timestamp":"'$TIMESTAMP'","placeholder":true}')

# Append to log
if [ ! -f "$LOG_FILE" ]; then
  echo '{"date":"'$DATE'","sessions":[]}' > "$LOG_FILE"
fi

# Update log file with new session data
# (Requires jq to merge JSON)
jq --argjson entry "$USAGE" '.sessions += [$entry]' "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

echo "✅ Usage logged to $LOG_FILE"
```

### 2. **Heartbeat Integration**

Add to `HEARTBEAT.md`:

```markdown
## Usage Monitoring (Check 2x daily)

- Query current usage via session_status
- Compare against thresholds
- Alert if approaching limits
- Suggest optimizations if needed
```

**Check schedule:**
- Morning (9 AM): After night's potential activity
- Evening (6 PM): Before evening work sessions

### 3. **Dashboard Script**

**Location:** `/home/theo/clawd/scripts/usage-dashboard.sh`

```bash
#!/bin/bash
# Show usage dashboard for current day/week/month

echo "📊 Claude Usage Dashboard"
echo "========================"
echo ""

# Today
TODAY=$(date +%Y-%m-%d)
if [ -f "memory/usage-logs/$TODAY.json" ]; then
  echo "📅 Today ($TODAY):"
  jq -r '.daily_totals | "  Tokens: \(.inputTokens + .outputTokens | tonumber) | Cost: $\(.costUSD) | Sessions: \(.sessionsCount)"' "memory/usage-logs/$TODAY.json"
fi

echo ""

# This week (last 7 days)
echo "📆 Last 7 Days:"
TOTAL_COST=0
for i in {0..6}; do
  DATE=$(date -d "$i days ago" +%Y-%m-%d 2>/dev/null || date -v-${i}d +%Y-%m-%d)
  if [ -f "memory/usage-logs/$DATE.json" ]; then
    COST=$(jq -r '.daily_totals.costUSD // 0' "memory/usage-logs/$DATE.json")
    TOTAL_COST=$(echo "$TOTAL_COST + $COST" | bc)
  fi
done
echo "  Total Cost: \$$TOTAL_COST"

echo ""

# Alerts
echo "⚠️  Alerts:"
if [ -f "memory/usage-logs/$TODAY.json" ]; then
  ALERTS=$(jq -r '.alerts[]? // "None"' "memory/usage-logs/$TODAY.json")
  if [ "$ALERTS" == "None" ]; then
    echo "  ✅ No alerts"
  else
    echo "$ALERTS"
  fi
fi
```

### 4. **Optimization Suggestions**

When approaching limits, automatically suggest:

**Reduce token usage:**
- Use smaller models for simple tasks (Haiku instead of Sonnet)
- Shorter prompts (be concise)
- Avoid re-reading large files repeatedly
- Use caching effectively (prompt caching)
- Batch operations instead of many small calls

**Prioritize tasks:**
- Critical: User-facing responses, urgent work
- Normal: Regular tasks, background work
- Low: Nice-to-have optimizations, exploration

**Defer non-urgent:**
- Move some work to off-peak hours
- Queue tasks for later when usage resets

---

## Integration Points

### A. Clawdbot Gateway Hook

If Clawdbot supports usage hooks, register a callback:

```javascript
// Pseudocode
gateway.onSessionEnd((session) => {
  logUsage({
    timestamp: Date.now(),
    model: session.model,
    inputTokens: session.inputTokens,
    outputTokens: session.outputTokens,
    cost: session.cost
  });
  
  checkThresholds();
});
```

### B. Manual Logging

After significant sessions:
```bash
# Log usage manually
./scripts/log-usage.sh

# Check dashboard
./scripts/usage-dashboard.sh
```

### C. Heartbeat Checks

Every heartbeat (every ~30 min):
```bash
# Quick check
USAGE_PERCENT=$(./scripts/check-usage-percent.sh)
if [ $USAGE_PERCENT -gt 70 ]; then
  echo "⚠️ Usage at ${USAGE_PERCENT}% - approaching limit"
fi
```

---

## Alert Delivery

**Methods:**
1. **Telegram message** - Direct notification via Clawdbot
2. **Console warning** - Show in next response
3. **Log file** - Record in daily log
4. **Email** (if Gmail configured) - Critical alerts only

**Example Alert:**
```
⚠️ Claude Usage Alert

Current usage: 72% of daily token limit
Estimated cost today: $7.20 / $10.00 budget

Recommendations:
- Use Haiku model for simple tasks
- Defer non-urgent work
- Review memory file sizes (large context)

Dashboard: /home/theo/clawd/memory/usage-logs/2026-01-27.json
```

---

## Setup Checklist

- [ ] Create usage-logs directory structure
- [ ] Implement log-usage.sh script
- [ ] Implement usage-dashboard.sh script
- [ ] Configure thresholds based on actual limits
- [ ] Add usage checks to HEARTBEAT.md
- [ ] Test alert system
- [ ] Document how to check usage manually
- [ ] Set up weekly usage reports
- [ ] Create optimization guidelines document

---

## Quick Commands Reference

```bash
# Check today's usage
./scripts/usage-dashboard.sh

# Log current session manually
./scripts/log-usage.sh

# View raw logs
cat memory/usage-logs/$(date +%Y-%m-%d).json | jq

# Weekly summary
./scripts/usage-dashboard.sh --week

# Check if approaching limit
./scripts/check-usage-percent.sh
```

---

## Future Enhancements

1. **Usage Prediction:** ML model to predict when you'll hit limits
2. **Smart Scheduling:** Queue low-priority tasks for off-peak
3. **Cost Optimization:** Automatic model selection based on task complexity
4. **Historical Analysis:** Trends, patterns, usage by task type
5. **Budget Tracking:** Monthly spend tracking with forecasts

---

## Notes

- **First priority:** Get actual limits from Anthropic console
- **Second priority:** Basic logging + alerts
- **Third priority:** Optimization automation

**Action:** Check https://console.anthropic.com/settings/limits for your actual Pro plan details.
