# Smart Spawn - Quick Start

**TL;DR:** Replace `openclaw spawn` with `smart-spawn.sh` to prevent rate limit errors.

---

## 1. Spawn an Agent (Safe)

```bash
# Instead of: openclaw spawn --label my-agent --task "Debug issue"
~/clawd/scripts/smart-spawn.sh "Debug issue" my-agent
```

**What it does:**
- ✓ Checks token budget before spawning
- ✓ Auto-detects task size (light/medium/heavy)
- ✓ Waits if budget insufficient
- ✓ Logs decision to Mission Control

---

## 2. Check Token Budget

```bash
# Quick status
~/clawd/scripts/token-utils.sh status

# Full report with spawn capacity
~/clawd/scripts/token-utils.sh report
```

---

## 3. Use in Your Scripts

```bash
#!/usr/bin/env bash
source ~/clawd/scripts/token-utils.sh

# Check if safe before spawning
if is_spawn_safe 15000; then
    ~/clawd/scripts/smart-spawn.sh "Your task"
else
    echo "Not enough budget, waiting..."
    sleep 60
    ~/clawd/scripts/smart-spawn.sh "Your task"
fi
```

---

## Task Size Guide

Let the script auto-detect, or specify manually:

| Size | When to Use | Example |
|------|-------------|---------|
| `light` | Quick tasks (<30s) | "Check status", "Run test" |
| `medium` | Standard tasks (30s-2min) | "Create file", "Update docs" |
| `heavy` | Complex tasks (>2min) | "Debug issue", "Analyze data" |

```bash
# Auto-detect (recommended)
~/clawd/scripts/smart-spawn.sh "Debug complex issue"
# → Detects "heavy" from "debug" + "complex"

# Manual override
~/clawd/scripts/smart-spawn.sh "Some task" label heavy
```

---

## Parallel Spawns

**Safe combinations:**
- ✓ 3 light tasks at once
- ✓ 2 light + 1 medium
- ✓ 1 heavy task (uses full budget)

**Unsafe combinations:**
- ✗ 2 heavy tasks (exceeds limit)
- ✗ 3 medium tasks (exceeds limit)

The script will auto-wait if needed.

---

## Troubleshooting

**"Insufficient token budget" repeatedly?**
→ Main session using too many tokens. Wait 1 minute or check `token-utils.sh report`

**Spawn still hits rate limit?**
→ Multiple spawns from different sources. Coordinate timing or increase buffer in script.

---

## Full Documentation

- **Quick Reference:** `~/clawd/docs/SPAWN-CALCULATOR.md`
- **Integration Guide:** `~/clawd/docs/SPAWN-INTEGRATION-GUIDE.md`
- **Full Summary:** `~/clawd/docs/SMART-SPAWN-SUMMARY.md`

---

**Created:** 2026-02-26 | **Status:** ✅ Production Ready
