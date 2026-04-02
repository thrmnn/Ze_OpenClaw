# Ralph Loop - Autonomous Task Orchestration

**Ralph** is an autonomous agent orchestration system that continuously monitors your Trello board and spawns subagents to work on high-priority tasks.

## 🎯 How It Works

1. **Monitor** - Polls Trello "Current Sprint" list every 2 minutes
2. **Prioritize** - Ranks tasks by urgency keywords, due dates, and position
3. **Spawn** - Creates subagent for top priority task (if budget allows)
4. **Track** - Marks cards with 🤖 Ralph label, monitors progress
5. **Repeat** - Loops continuously until stopped

## 🚀 Quick Start

```bash
# Start Ralph Loop
bash ~/clawd/scripts/ralph-control.sh start

# Check status
bash ~/clawd/scripts/ralph-control.sh status

# Watch logs
bash ~/clawd/scripts/ralph-control.sh logs

# Stop Ralph
bash ~/clawd/scripts/ralph-control.sh stop
```

## 🎮 Control via Trello

**Pause Ralph** (temporary hold)
- Create a card named: `PAUSE RALPH`
- Ralph will check every loop and skip spawning
- Delete card to resume

**Stop Ralph** (complete shutdown)
- Create a card named: `STOP RALPH`
- Ralph will detect and exit gracefully
- Must restart manually after stopping

## 📋 Task Selection Logic

### Prioritization (in order):
1. **Priority keywords** - urgent, critical, blocker, deadline
2. **Due date** - Earlier due dates first
3. **List position** - Top of list first

### Filters:
- ✅ Tasks in "Current Sprint" list
- ✅ Not already labeled with 🤖 Ralph
- ❌ Skip tasks with: waiting, blocked, paused

### Example:
```
Current Sprint List:
┌─────────────────────────────────────┐
│ 🔥 URGENT: Fix production bug       │ ← Spawned first (urgent keyword)
│ Deploy new feature (due tomorrow)   │ ← Spawned next (due date)
│ 🤖 Update documentation             │ ← Skipped (already assigned)
│ Research new tools                   │ ← Spawned last (no priority)
│ [BLOCKED] Waiting for API access    │ ← Skipped (blocked keyword)
└─────────────────────────────────────┘
```

## 🛡️ Safety Features

### Token Budget Protection
- Checks budget before each spawn using `token-utils.sh`
- Waits 60s if budget too low (<8k tokens)
- Uses `smart-spawn.sh` for rate limit protection

### Concurrent Limit
- Default: Max 3 agents running simultaneously
- Configurable in `ralph-config.sh`
- Prevents resource exhaustion

### Graceful Shutdown
- Handles SIGINT/SIGTERM properly
- Saves state before exit
- Logs all actions to Mission Control

## 🔧 Configuration

Edit `~/clawd/scripts/ralph-config.sh`:

```bash
# Spawn limits
export RALPH_MAX_CONCURRENT=3          # Max agents at once
export RALPH_MIN_LOOP_DELAY=120        # Seconds between checks

# Task selection
export RALPH_PRIORITY_KEYWORDS="urgent|critical|blocker|deadline"
export RALPH_SKIP_KEYWORDS="waiting|blocked|paused"

# Control
export RALPH_PAUSE_CARD="PAUSE RALPH"
export RALPH_STOP_CARD="STOP RALPH"
```

## 📊 Monitoring

### Status Command
```bash
$ bash ~/clawd/scripts/ralph-control.sh status

=== Ralph Loop Status ===

Status: ✅ RUNNING (PID: 12345)

Loop Stats:
  Iterations: 47
  Total Spawns: 12
  Last Run: 2026-02-26T03:15:00Z

Active Spawns: 2
  - Fix production bug (started: 2026-02-26T03:10:00Z)
  - Deploy new feature (started: 2026-02-26T03:12:00Z)

Recent Log (last 5 lines):
  2026-02-26 00:15:00 [INFO] Spawned agent for: Fix production bug
  2026-02-26 00:15:05 [INFO] Sleeping for 120s...
  2026-02-26 00:17:05 [INFO] === Ralph Loop Iteration ===
  2026-02-26 00:17:06 [INFO] Active spawns: 2 / 3
  2026-02-26 00:17:07 [INFO] Found 5 available tasks
```

### Live Logs
```bash
bash ~/clawd/scripts/ralph-control.sh logs
```

### Mission Control Integration
Ralph logs all activity to Mission Control:
- `ralph_start` - Loop started
- `ralph_spawn` - Agent spawned for task
- `ralph_wait` - Waiting (max concurrent/low budget)
- `ralph_stop` - Loop stopped

## 🧠 State Files

Ralph maintains state in `~/clawd/memory/`:

**ralph-state.json** - Loop statistics
```json
{
  "loop_count": 47,
  "last_run": "2026-02-26T03:15:00Z",
  "total_spawns": 12
}
```

**ralph-spawns.json** - Active subagents
```json
[
  {
    "session_id": "1bee72bc-000c-410c-aee5-ccc7ce14acda",
    "card_id": "65f8a9b1c2d3e4f5g6h7i8j9",
    "card_name": "Fix production bug",
    "started_at": "2026-02-26T03:10:00Z",
    "status": "active"
  }
]
```

**ralph-loop.pid** - Process ID (when running)

## 🎭 Interaction Workflow

### User → Trello → Ralph

1. **Add task to Current Sprint**
   ```
   You: Create card "Build new feature"
   Trello: Card added to Current Sprint
   Ralph: Detects new card, spawns agent
   ```

2. **Prioritize urgent work**
   ```
   You: Rename card to "🔥 URGENT: Fix critical bug"
   Trello: Card updated
   Ralph: Sees urgent keyword, prioritizes next
   ```

3. **Block task temporarily**
   ```
   You: Rename to "[BLOCKED] Waiting for API"
   Trello: Card updated
   Ralph: Skips card (blocked keyword)
   ```

4. **Pause all work**
   ```
   You: Create card "PAUSE RALPH"
   Trello: Card created
   Ralph: Stops spawning, waits
   You: Delete "PAUSE RALPH" card
   Ralph: Resumes spawning
   ```

### Ralph → Trello → User

1. **Agent starts work**
   ```
   Ralph: Spawns agent for task
   Agent: Adds 🤖 Ralph label to card
   You: See label, know agent is working
   ```

2. **Agent updates progress**
   ```
   Agent: Adds comment with progress update
   You: Receive Trello notification
   ```

3. **Agent completes task**
   ```
   Agent: Moves card to "Done" list
   You: Verify completion, close or reopen
   ```

## 🔄 Integration with Other Systems

### Smart Spawn System
Ralph uses `smart-spawn.sh` for all spawns:
- Token budget protection
- Rate limit handling
- Auto-wait on insufficient budget

### Mission Control
All Ralph actions logged to Mission Control dashboard:
- Spawn events
- Wait/pause events
- Token budget decisions

### Memory System (QMD)
Agents can use QMD for context:
```bash
# Agent spawned by Ralph can search memory
qmd search "previous implementation of feature X"
```

### Trello Synthesis
Ralph reads from same board as `trello-synthesis.sh`:
- Consistent task structure
- Shared labels and lists
- Same credential file

## 🚨 Troubleshooting

### Ralph not spawning agents
1. Check status: `bash ~/clawd/scripts/ralph-control.sh status`
2. Check logs: `bash ~/clawd/scripts/ralph-control.sh logs`
3. Verify Trello credentials: `source ~/clawd/credentials/trello.env && echo $TRELLO_API_KEY`
4. Check token budget: `bash ~/clawd/scripts/token-utils.sh report`

### Ralph spawned agent for wrong task
- Check prioritization keywords in `ralph-config.sh`
- Verify task names match skip/priority patterns
- Use [BLOCKED] prefix to skip specific tasks

### Too many agents running
- Reduce `RALPH_MAX_CONCURRENT` in config
- Create "PAUSE RALPH" card to stop new spawns
- Kill specific spawns: `openclaw sessions list` → `openclaw kill <id>`

### Ralph stuck waiting
- Check token budget: `bash ~/clawd/scripts/token-utils.sh report`
- Wait 60s for budget recovery
- Or kill agents to free tokens: `openclaw kill <id>`

## 🎓 Best Practices

### Task Card Structure
```markdown
Title: Clear, actionable description
Labels: Priority, type, area
Due Date: If time-sensitive
Description:
  - What needs to be done
  - Acceptance criteria
  - Links to resources
  - Constraints or requirements
```

### Using Control Cards
- **PAUSE**: Use during meetings, focus time, or when reviewing work
- **STOP**: Use when making config changes or debugging Ralph
- Delete control cards promptly to resume

### Monitoring Ralph
- Check status 2-3 times per day
- Review Mission Control dashboard
- Read spawn logs to learn agent performance
- Adjust priorities based on outcomes

### Token Management
- Ralph respects token limits automatically
- If budget low, agents wait (no failures)
- Monitor daily usage via Mission Control
- Adjust `RALPH_MAX_CONCURRENT` if burning too fast

## 📈 Advanced Usage

### Custom Spawn Labels
Edit task card prompt in `ralph-loop.sh` function `spawn_for_task()`:
```bash
local task_prompt="Complete Trello task: ${card_name}
... (add custom instructions here) ..."
```

### Integration with Cron
```bash
# Start Ralph at boot
@reboot bash /home/theo/clawd/scripts/ralph-control.sh start

# Auto-restart daily (optional)
0 0 * * * bash /home/theo/clawd/scripts/ralph-control.sh restart
```

### Mission Control Webhooks (future)
Ralph could trigger webhooks on key events:
- Agent spawn → Slack notification
- Task complete → Update dashboard
- Budget low → Alert via Telegram

## 🎯 Success Metrics

Track Ralph's effectiveness:
- **Spawn Rate**: Tasks/hour (higher = more productive)
- **Completion Rate**: Done cards / Spawned agents
- **Token Efficiency**: Cost per completed task
- **Wait Time**: % of iterations waiting vs spawning

View in Mission Control dashboard or parse logs:
```bash
# Total spawns today
grep "Spawned agent" ~/clawd/logs/ralph-loop.log | grep "$(date +%Y-%m-%d)" | wc -l

# Wait events today
grep "waiting:" ~/clawd/logs/ralph-loop.log | grep "$(date +%Y-%m-%d)" | wc -l
```

## 🛠️ Files Reference

| File | Purpose |
|------|---------|
| `scripts/ralph-loop.sh` | Main orchestration loop |
| `scripts/ralph-config.sh` | Configuration settings |
| `scripts/ralph-control.sh` | Start/stop/status control |
| `memory/ralph-state.json` | Loop statistics |
| `memory/ralph-spawns.json` | Active agents tracking |
| `memory/ralph-loop.pid` | Process ID when running |
| `logs/ralph-loop.log` | Detailed activity log |

---

**Ralph Loop Status**: 🟢 Production Ready
**Version**: 1.0
**Last Updated**: 2026-02-26
