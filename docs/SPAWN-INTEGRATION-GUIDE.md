# Spawn Integration Guide

Quick guide for integrating smart-spawn into existing workflows.

---

## Integration Methods

### Method 1: Direct Script Usage

Replace direct `openclaw spawn` calls with `smart-spawn.sh`:

**Before:**
```bash
openclaw spawn --label my-agent --task "Debug issue"
```

**After:**
```bash
~/clawd/scripts/smart-spawn.sh "Debug issue" my-agent
```

---

### Method 2: Using Token Utils in Custom Scripts

Source the token utilities to add budget checks to your own scripts:

```bash
#!/usr/bin/env bash
source ~/clawd/scripts/token-utils.sh

# Check if safe to spawn
if is_spawn_safe 15000; then
    echo "✓ Safe to spawn medium task"
    openclaw spawn --label my-agent --task "Your task"
else
    available=$(get_available_budget)
    echo "⚠ Only $available tokens available, need 15000"
    echo "Waiting 60s for budget refresh..."
    sleep 60
    openclaw spawn --label my-agent --task "Your task"
fi
```

---

### Method 3: Pre-Flight Checks

Check token budget before bulk operations:

```bash
#!/usr/bin/env bash
source ~/clawd/scripts/token-utils.sh

# Print budget report before spawning multiple agents
print_budget_report

# Check if we can spawn 3 light agents
available=$(get_available_budget)
required=$((3 * 8000))  # 3 light agents

if [ "$available" -ge "$required" ]; then
    echo "✓ Sufficient budget for 3 agents"
    ~/clawd/scripts/smart-spawn.sh "Task 1" agent-1 light
    ~/clawd/scripts/smart-spawn.sh "Task 2" agent-2 light
    ~/clawd/scripts/smart-spawn.sh "Task 3" agent-3 light
else
    echo "⚠ Insufficient budget, spawning sequentially"
    ~/clawd/scripts/smart-spawn.sh "Task 1" agent-1 light
    sleep 30
    ~/clawd/scripts/smart-spawn.sh "Task 2" agent-2 light
    sleep 30
    ~/clawd/scripts/smart-spawn.sh "Task 3" agent-3 light
fi
```

---

## Common Patterns

### Pattern 1: Morning Brief Spawn

```bash
# In your morning brief script
source ~/clawd/scripts/token-utils.sh

# Get current budget
current=$(get_current_tokens)
available=$(get_available_budget "$current")

if [ "$available" -ge 15000 ]; then
    ~/clawd/scripts/smart-spawn.sh \
        "Generate morning brief with calendar and email summary" \
        morning-brief \
        medium
else
    echo "⚠ Skipping morning brief spawn - insufficient budget"
fi
```

### Pattern 2: Heartbeat Task Spawning

```bash
# In your heartbeat handler
source ~/clawd/scripts/token-utils.sh

# Check if there are pending tasks
if [ -f ~/clawd/queue/pending-tasks.txt ]; then
    while IFS= read -r task; do
        # Try to spawn each task
        if is_spawn_safe 8000; then
            ~/clawd/scripts/smart-spawn.sh "$task" "heartbeat-task" light
        else
            echo "⚠ Budget limit reached, remaining tasks queued"
            break
        fi
    done < ~/clawd/queue/pending-tasks.txt
fi
```

### Pattern 3: Conditional Spawn by Time

```bash
# Only spawn heavy tasks during off-peak hours
source ~/clawd/scripts/token-utils.sh

hour=$(date +%H)

if [ "$hour" -ge 22 ] || [ "$hour" -le 6 ]; then
    # Off-peak: safe to spawn heavy tasks
    ~/clawd/scripts/smart-spawn.sh \
        "Run comprehensive analysis" \
        night-analyzer \
        heavy
else
    # Peak hours: prefer light tasks
    ~/clawd/scripts/smart-spawn.sh \
        "Quick status check" \
        day-checker \
        light
fi
```

---

## Quick Reference Commands

```bash
# Check current token usage
~/clawd/scripts/token-utils.sh current

# Check available budget
~/clawd/scripts/token-utils.sh available

# Get status summary
~/clawd/scripts/token-utils.sh status

# Full budget report
~/clawd/scripts/token-utils.sh report

# Check if spawn is safe for 15k tokens
~/clawd/scripts/token-utils.sh safe 15000

# Get recommended wait time for 30k token task
~/clawd/scripts/token-utils.sh wait 30000

# Spawn with auto task size detection
~/clawd/scripts/smart-spawn.sh "Your task description"

# Spawn with explicit size
~/clawd/scripts/smart-spawn.sh "Your task" label heavy
```

---

## Troubleshooting

### "openclaw: command not found"

**Solution:** Add OpenClaw to PATH or use full path:
```bash
export PATH="$HOME/.nvm/versions/node/v24.12.0/bin:$PATH"
# Or use absolute path in script
```

### Token usage shows 0

**Likely causes:**
1. Running in subagent (can't access parent session status)
2. OpenClaw not configured properly

**Solution:** This is safe - script defaults to 0 tokens (conservative estimate)

### Spawns still hitting rate limits

**Possible causes:**
1. Multiple parallel spawns from different sources
2. Cached tokens counting toward limit
3. External API usage not tracked by script

**Solutions:**
- Reduce `SAFE_THRESHOLD` to 0.65 (65%)
- Increase `BUFFER_TOKENS` to 10000
- Add delays between spawns: `sleep 5`

---

## Best Practices

1. **Always use smart-spawn for production spawns**
   - Prevents rate limit errors
   - Automatic retry logic
   - Mission Control logging

2. **Source token-utils for custom logic**
   - Reusable functions
   - Consistent budget calculations
   - Easy integration

3. **Monitor spawn patterns**
   - Check Mission Control for spawn frequency
   - Review token usage trends
   - Adjust task sizes if estimates are wrong

4. **Set task size hints in descriptions**
   - "Quick check..." → auto-detects as light
   - "Debug complex..." → auto-detects as heavy
   - Clear descriptions improve auto-detection

---

**Created:** 2026-02-26  
**Maintainer:** Zé (smart-spawn-system subagent)
