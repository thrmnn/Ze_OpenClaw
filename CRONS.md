# OpenClaw Cron Registry

> Single source of truth for all scheduled jobs. Last audited: 2026-03-19.

## Active Crons (20)

| # | Name | ID (short) | Schedule | TZ | Purpose | Target | Status |
|---|------|-----------|----------|-----|---------|--------|--------|
| 1 | mc-sync-agents | `dd5c1482` | every 2m | - | Sync active OpenClaw sessions to Mission Control | main | Active |
| 2 | End-of-Day Review | `617f0be9` | 17:50 Mon-Fri | BRT | Summarize day, update daily note, draft tomorrow's 3-3-3, Telegram summary (skips if inactive) | main | Active |
| 3 | Persist Gateway Logs | `5df58b82` | 23:00 daily | BRT | Run `persist-logs.sh` to save gateway logs | main | Active |
| 4 | Daily Auto-Commit | `2b342849` | 23:55 daily | BRT | Auto-commit memory/, MEMORY.md, active-tasks.json to git | main | Active |
| 5 | Pre-Workout Meal Reminder | `631b26f9` | 06:30 Mon-Sat | BRT | Notification: pre-workout meal 60-90min before training | main | Active |
| 6 | daily-qmd-update | `86aa2d13` | 07:30 daily | BRT | Run `qmd update && qmd embed` to refresh knowledge base | main | Active |
| 7 | Morning Health Brief | `ed359955` | 07:30 Mon-Fri | BRT | Notification: check training program, pre-workout meal, carb day type | main | Active |
| 8 | Heartbeat Freshness Check | `01754e7f` | 08:00 daily | BRT | Run `check-heartbeat-freshness.sh` to verify system health | main | Active |
| 9 | Obsidian Morning Routine | `91d9e31c` | 08:00 daily | BRT | Run `obsidian-morning-routine.sh`, read vaults, fill 3-3-3, Telegram morning summary | main | Active |
| 10 | Trading Pre-Market Scan | `92d8a353` | 08:30 Mon-Fri | BRT | Run `~/projects/trading-bot/main.py --scan` for crypto/forex/gold setups | main | Active |
| 11 | Position Radar Daily Scan | `1dd0ba41` | 09:00 daily | BRT | Run `~/projects/position-radar/radar.py` \u2014 fetch, score, queue new job positions | isolated | Active |
| 12 | Obsidian Vault Maintenance | `770ec22d` | 15:00 daily | BRT | Update 4 vault dashboards, clean empty notes, fix broken links, archive done interviews | isolated | Active |
| 13 | Weekly Review (Friday) | `4760c43b` | 18:00 Fri | BRT | Run `obsidian-weekly-review.sh`, close the week, archive done tasks, plan next week, Telegram | main | Active |
| 14 | Obsidian SSD Backup Reminder | `f6c0a584` | 10:00 Sat | BRT | Notification: plug in external drive and run `obsidian-backup-ssd.sh` | main | Active |
| 15 | Weekly Progress Check | `1fb04fda` | 09:00 Sun | BRT | Notification: log weight + measurements, update Habit-Tracker.md | main | Active |
| 16 | Weekly Meal Prep Reminder | `83e5a698` | 10:00 Sun | BRT | Notification: check Batch-Cooking-Guide.md, prep proteins and rice | main | Active |
| 17 | Weekly Digest Email | `0c6f157d` | 19:00 Sun | BRT | Run `weekly-digest.py` \u2014 send weekly digest email to Theo | main | Active |
| 18 | Sunday Mini-Review | `c0d64430` | 20:00 Sun | BRT | Light weekend review if active: update Monday's daily note, Telegram (skips if inactive) | main | Active |
| 19 | Obsidian Git Backup | `8d1b711d` | 23:00 Sun | BRT | Run `obsidian-backup-git.sh` \u2014 weekly git backup of all vaults | main | Active |
| 20 | Daily Note Generator | `10d437b0` | 08:05 daily | BRT | Run `generate-daily-note.py` \u2014 auto-generate Obsidian daily note with training + priorities | main | Active |

## Disabled/Killed Crons

| Name | ID (short) | Reason | Date |
|------|-----------|--------|------|
| Position Radar Scan | `5f37c664` | Duplicate of #11 \u2014 was firing at 9am+6pm weekdays, overlapping with daily scan at 9am | 2026-03-19 |

## Schedule Overview (Weekday)

```
06:30  Pre-Workout Meal Reminder
07:30  daily-qmd-update + Morning Health Brief
08:00  Heartbeat Freshness Check + Obsidian Morning Routine
08:05  Daily Note Generator
08:30  Trading Pre-Market Scan
09:00  Position Radar Daily Scan
15:00  Obsidian Vault Maintenance
17:50  End-of-Day Review
23:00  Persist Gateway Logs
23:55  Daily Auto-Commit
  +    mc-sync-agents (every 2m, always running)
```

## Schedule Overview (Weekend)

```
Saturday:
  06:30  Pre-Workout Meal Reminder
  07:30  daily-qmd-update
  08:00  Heartbeat/Obsidian Morning
  08:05  Daily Note Generator
  09:00  Position Radar
  10:00  Obsidian SSD Backup Reminder
  15:00  Obsidian Vault Maintenance
  23:00  Persist Gateway Logs
  23:55  Daily Auto-Commit

Sunday:
  07:30  daily-qmd-update
  08:00  Heartbeat/Obsidian Morning
  08:05  Daily Note Generator
  09:00  Position Radar + Weekly Progress Check
  10:00  Weekly Meal Prep Reminder
  15:00  Obsidian Vault Maintenance
  19:00  Weekly Digest Email
  20:00  Sunday Mini-Review
  23:00  Persist Gateway Logs + Obsidian Git Backup
  23:55  Daily Auto-Commit
```

## Path Audit (2026-03-19)

All cron targets verified:
- `~/clawd/scripts/sync-active-agents.sh` \u2014 exists
- `~/clawd/scripts/persist-logs.sh` \u2014 exists
- `~/clawd/scripts/check-heartbeat-freshness.sh` \u2014 exists
- `~/clawd/scripts/obsidian-morning-routine.sh` \u2014 exists
- `~/clawd/scripts/obsidian-weekly-review.sh` \u2014 exists
- `~/clawd/scripts/obsidian-backup-ssd.sh` \u2014 exists
- `~/clawd/scripts/obsidian-backup-git.sh` \u2014 exists
- `~/clawd/scripts/weekly-digest.py` \u2014 exists
- `~/projects/trading-bot/main.py` \u2014 exists
- `~/projects/position-radar/radar.py` \u2014 exists
- `qmd` (via `~/.bun/bin/qmd`) \u2014 exists
- `~/clawd/scripts/generate-daily-note.py` \u2014 exists
- Obsidian vault paths (4 vaults) \u2014 all exist

## Categories

**System/Infra:** mc-sync-agents, Persist Gateway Logs, Daily Auto-Commit, Heartbeat Freshness Check
**Obsidian:** Morning Routine, Daily Note Generator, Vault Maintenance, SSD Backup, Git Backup, Weekly Review, Sunday Mini-Review
**Trading/Jobs:** Trading Pre-Market Scan, Position Radar Daily Scan
**Health/Fitness:** Pre-Workout Meal, Morning Health Brief, Weekly Progress Check, Weekly Meal Prep
**Comms:** End-of-Day Review, Weekly Digest Email
**Knowledge:** daily-qmd-update
