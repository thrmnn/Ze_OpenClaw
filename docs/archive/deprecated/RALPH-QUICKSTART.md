# Ralph Loop - Quick Start

**Ralph** autonomously monitors your Trello board and spawns agents to complete tasks.

## 🚀 Start Ralph

```bash
bash ~/clawd/scripts/ralph-control.sh start
```

## 🎮 Control via Trello

**Interact with Ralph by managing your Trello board:**

1. **Add tasks** → "Current Sprint" list
2. **Prioritize** → Add keywords: urgent, critical, deadline
3. **Pause** → Create card: "PAUSE RALPH"
4. **Resume** → Delete "PAUSE RALPH" card
5. **Stop** → Create card: "STOP RALPH"

**Ralph will:**
- ✅ Detect new tasks every 2 minutes
- ✅ Spawn agents for top priority tasks
- ✅ Mark cards with 🤖 Ralph label
- ✅ Respect token budgets and rate limits
- ✅ Run max 3 agents simultaneously

## 📊 Monitor Ralph

```bash
# Check status
bash ~/clawd/scripts/ralph-control.sh status

# Watch live logs
bash ~/clawd/scripts/ralph-control.sh logs

# Stop Ralph
bash ~/clawd/scripts/ralph-control.sh stop
```

## 🎯 Task Priority

Ralph picks tasks in this order:
1. **Keywords** - urgent, critical, blocker, deadline
2. **Due dates** - Earlier first
3. **Position** - Top of list first

**Skip patterns** - Ralph ignores cards with:
- waiting, blocked, paused keywords
- Already marked with 🤖 Ralph label

## 🛡️ Safety Features

- **Token budget protection** - Waits if budget low
- **Rate limit handling** - Uses smart-spawn system
- **Concurrent limit** - Max 3 agents (configurable)
- **Graceful shutdown** - Ctrl+C or STOP card

## 🔧 Configuration

Edit: `~/clawd/scripts/ralph-config.sh`

```bash
# Key settings
RALPH_MAX_CONCURRENT=3        # Max agents at once
RALPH_MIN_LOOP_DELAY=120      # Seconds between checks
```

## 📚 Full Documentation

Read: `~/clawd/docs/RALPH-LOOP.md`

---

**Status**: 🟢 Ready to start
**Version**: 1.0
**Test**: `bash ~/clawd/scripts/test-ralph.sh`
