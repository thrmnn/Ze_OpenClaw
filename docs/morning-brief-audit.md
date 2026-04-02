# Morning Brief — Audit & Redesign Plan

> Audited: 2026-03-23

---

## Current State — What's Broken

### `scripts/morning-brief.sh`
| Component | Status | Issue |
|-----------|--------|-------|
| Tasks section | ❌ | Still calls `trello-synthesis.sh` — Trello is dead |
| AI updates | ❌ | Placeholder ("awaiting voices list") — never implemented |
| News | ❌ | Hardcoded fake strings |
| Quotes | ⚠️ | Only 12 quotes, will repeat quickly |
| Calendar | ❌ | Not included at all |
| Email | ❌ | Not included |
| Job pipeline | ❌ | Not included |
| Position Radar | ❌ | Not included |

### Cron landscape — too fragmented
Running 6+ separate crons between 7-8am (Brazil):
- Morning Health Brief (7:30am)
- Health Morning Log (8:00am)
- Obsidian Morning Routine (8:00am)
- Daily Note Generator (8:05am)
- Trading Pre-Market Scan (8:30am)
- Heartbeat Freshness Check (8:00am)

Each runs independently → no unified output → cognitive overhead.

### Other bugs found
- `Position Radar Daily` cron → **error** state (needs investigation)
- `morning-brief.sh` sends to stdout only — not wired to Telegram via OpenClaw

---

## Redesigned Architecture — Multi-Agent Morning Brief

### Principle
One orchestrator triggers 4 parallel data agents → waits → synthesizes → sends to Telegram.

```
[Orchestrator] (8:00 AM Brazil, weekdays)
      ├── Agent 1: Calendar      → next 3 events today
      ├── Agent 2: Email         → urgent/unread count + flagged senders  
      ├── Agent 3: Job Pipeline  → active applications + new radar hits
      └── Agent 4: Health/Habits → pre-workout reminder, streak status
                ↓ (all parallel, ~30s)
      [Synthesizer Agent] → formats unified brief → sends via Telegram
```

### Output Format (target)
```
☀️ Bonjour Théo — [Day], [Date]

📅 Today:
• [Event 1 — time]
• [Event 2 — time]
• No other events

📬 Inbox: 3 new (1 flagged — [sender])

🎯 Focus:
• Top priority from Mission Control
• [Job app status if active]

🤖 Radar: [N new jobs above 70% — or "nothing new"]

💭 "[Quote]" — [Author]
```

Clean, scannable, actionable. No fake news, no fluff.

---

## Implementation Plan

### Phase 1 — Fix broken pieces (quick wins)
1. Remove Trello call → replace with Mission Control API fetch
2. Wire output to Telegram (use OpenClaw cron prompt, not bash send)
3. Add calendar integration (already working via `calendar-check.sh`)
4. Fix Position Radar cron error

### Phase 2 — Multi-agent rewrite
1. Build `scripts/morning-brief-v2.py` — orchestrator script
2. Parallel fetch functions:
   - `fetch_calendar()` — Google Calendar API (next 24h)
   - `fetch_email()` — Gmail API (unread + flagged)
   - `fetch_job_pipeline()` — SQLite tracker + radar results
   - `fetch_mc_tasks()` — Mission Control API top tasks
3. Synthesizer: pass all data to Claude → generate brief prose
4. Send via Telegram

### Phase 3 — Consolidate crons
Merge fragmented 7-8am crons into one unified morning brief cron.
Keep only:
- Morning Brief (8:00am) — new unified one
- Pre-Workout Meal Reminder (6:30am) — keep separate, different purpose
- Trading Pre-Market Scan (8:30am) — keep separate

---

## Files to create/modify
- `scripts/morning-brief-v2.py` — new orchestrator (replaces morning-brief.sh)
- `scripts/fetch-calendar.py` — extracted calendar module  
- `scripts/fetch-email-summary.py` — extracted email module
- Update OpenClaw cron "Morning Health Brief" → point to new script

---

## Quick Test Checklist
- [ ] Calendar fetch returns real events
- [ ] Email fetch returns real unread count
- [ ] Job pipeline returns correct active apps
- [ ] Mission Control returns top tasks
- [ ] Synthesized brief arrives on Telegram by 8:05am
- [ ] Brief is ≤300 words
- [ ] Position Radar cron error fixed
