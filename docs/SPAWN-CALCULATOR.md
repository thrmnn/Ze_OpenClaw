# Spawn Calculator - Quick Reference

**Purpose:** Intelligent spawn orchestration that prevents API rate limit errors by checking token budget before spawning subagents.

---

## Quick Usage

```bash
# Basic usage (auto-detects task size)
~/clawd/scripts/smart-spawn.sh "Debug mission control integration"

# With custom label
~/clawd/scripts/smart-spawn.sh "Create new skill" my-skill-agent

# Specify task size manually
~/clawd/scripts/smart-spawn.sh "Complex analysis task" analyzer heavy
```

---

## Task Size Classification

| Size | Token Cost | Duration | Examples |
|------|-----------|----------|----------|
| **light** | 8,000 | <30s | Test, check, status, read, list, simple queries |
| **medium** | 15,000 | 30s-2min | Skill execution, file operations, standard tasks |
| **heavy** | 30,000 | >2min | Analysis, debug, investigation, refactoring, optimization |

**Auto-detection keywords:**
- **Heavy:** analysis, analyze, complex, debug, investigate, refactor, optimize
- **Light:** test, check, simple, quick, status, read, list
- **Medium:** Everything else (default)

---

## Token Budget Calculation

### Rate Limit (Tier 1)
- **Limit:** 40,000 tokens/minute
- **Safe threshold:** 30,000 tokens (75% of limit)
- **Buffer:** 5,000 tokens (reserved for main agent)
- **Available pool:** 25,000 tokens/minute for spawns

### Formula

```
Available Budget = Safe Limit - Current Usage - Buffer
                 = 30,000 - Current Tokens - 5,000
```

**Decision Logic:**
```
IF Available Budget ≥ Estimated Cost:
    → Spawn immediately
ELSE:
    → Wait 60 seconds for rate limit window to roll
    → Retry spawn
```

---

## Parallel Spawn Capacity

| Scenario | Light (8k) | Medium (15k) | Heavy (30k) |
|----------|-----------|-------------|-------------|
| **Max Parallel** | 3 agents | 1-2 agents | 1 agent |
| **Safe Mix** | 2 light + 1 medium | 1 medium | 1 heavy (uses full budget) |

**Examples:**
- ✓ Spawn 2 light tasks simultaneously (16k < 25k)
- ✓ Spawn 1 medium task (15k < 25k)
- ✗ Spawn 2 medium tasks (30k > 25k) → Sequential
- ✗ Spawn 1 heavy + 1 light (38k > 25k) → Sequential

---

## Checking Current Token Usage

### Option 1: Session Status Command
```bash
openclaw session_status | grep -i tokens
```

**Output example:**
```
Tokens: 12,345 / 200,000
```

### Option 2: Helper Function (in script)
```bash
# Extract tokens from session status
get_current_tokens() {
    openclaw session_status 2>/dev/null | \
        grep -oP 'tokens?:\s*\K\d+' | \
        head -1 || echo "0"
}

current=$(get_current_tokens)
echo "Current token usage: $current"
```

### Option 3: Direct from Script
```bash
# The smart-spawn.sh script handles this automatically
./scripts/smart-spawn.sh "task" # Shows token info in logs
```

---

## Mission Control Integration

The script automatically logs spawn decisions to Mission Control:

**Events logged:**
- `SPAWN_OK` - Sufficient budget, spawned immediately
- `WAIT_BUDGET` - Insufficient budget, waiting for refresh

**Log format:**
```json
{
  "type": "spawn_decision",
  "message": "Decision: SPAWN_OK | Task: Debug task | Used: 15k | Available: 20k",
  "agent": "smart-spawn",
  "timestamp": "2026-02-26T00:00:00Z"
}
```

---

## Safety Features

1. **Rate Limit Protection**
   - Never exceeds 75% of API rate limit
   - Reserves buffer for main agent responsiveness

2. **Auto-Wait**
   - If budget insufficient, waits 60s for rate limit window to roll
   - Automatic retry after wait

3. **Token Tracking**
   - Real-time budget calculation from session_status
   - Transparent logging of decisions

4. **Fallback Handling**
   - If session_status unavailable, assumes 0 tokens (safe default)
   - Graceful degradation

---

## Examples

### Example 1: Light Task (Immediate Spawn)
```bash
$ ./scripts/smart-spawn.sh "Run quick test" test-agent light

[2026-02-26 00:00:00] Auto-detected task size: light
[2026-02-26 00:00:00] Checking current token budget...
[2026-02-26 00:00:00] Current session tokens: 5000
[2026-02-26 00:00:00] Available token budget: 20000 (Safe limit: 30000)
[2026-02-26 00:00:00] ✓ Safe to spawn (8000 tokens < 20000 available)
[2026-02-26 00:00:00] Spawning agent: test-agent
[2026-02-26 00:00:00] ✓ Agent spawned successfully
```

### Example 2: Heavy Task (Wait Required)
```bash
$ ./scripts/smart-spawn.sh "Complex analysis" analyzer heavy

[2026-02-26 00:00:00] Checking current token budget...
[2026-02-26 00:00:00] Current session tokens: 22000
[2026-02-26 00:00:00] Available token budget: 3000 (Safe limit: 30000)
[2026-02-26 00:00:00] ⚠ Insufficient budget (30000 tokens > 3000 available)
[2026-02-26 00:00:00] Insufficient token budget. Waiting 60s for refresh...
[2026-02-26 00:01:00] Retrying spawn after budget refresh...
[2026-02-26 00:01:00] ✓ Agent spawned successfully (after wait)
```

### Example 3: Auto-Detection
```bash
# Heavy task (contains "debug")
$ ./scripts/smart-spawn.sh "Debug integration issue"
# → Detects as "heavy" (30k tokens)

# Light task (contains "check")
$ ./scripts/smart-spawn.sh "Check file status"
# → Detects as "light" (8k tokens)

# Medium task (default)
$ ./scripts/smart-spawn.sh "Update documentation"
# → Detects as "medium" (15k tokens)
```

---

## Best Practices

1. **Use task size hints in descriptions:**
   - "Quick check..." → auto-detects as light
   - "Debug complex..." → auto-detects as heavy

2. **Monitor token usage:**
   - Check `openclaw session_status` before bulk spawns
   - Use Mission Control dashboard to track spawn history

3. **Batch sequential tasks:**
   - If spawning multiple heavy tasks, let script handle waits
   - Don't manually spawn in parallel without checking budget

4. **Override auto-detection when needed:**
   - If auto-detection is wrong, specify size manually
   - Example: `./smart-spawn.sh "test" label heavy` (forces heavy)

---

## Troubleshooting

### Issue: "Insufficient token budget" repeatedly

**Cause:** Main session using too many tokens  
**Solution:**
- Wait for rate limit window to roll (1 minute)
- Check for other active subagents consuming tokens
- Consider using lighter tasks or reducing context

### Issue: Script can't fetch session_status

**Cause:** OpenClaw CLI not in PATH  
**Solution:**
- Run from correct directory: `cd ~/clawd`
- Check OpenClaw installation: `which openclaw`

### Issue: Spawn still hits rate limit

**Cause:** External factors (other API calls, cached tokens)  
**Solution:**
- Increase buffer: Edit `BUFFER_TOKENS` in script
- Reduce safe threshold: Change `SAFE_THRESHOLD` to 0.65 (65%)

---

## References

- **Rate Limit Analysis:** `~/clawd/docs/RATE-LIMIT-ANALYSIS.md`
- **Anthropic API Docs:** https://docs.anthropic.com/en/api/rate-limits
- **Mission Control:** https://mission-control-ruby-zeta.vercel.app/

---

**Last Updated:** 2026-02-26  
**Script Location:** `~/clawd/scripts/smart-spawn.sh`  
**Maintainer:** Zé (smart-spawn-system subagent)
