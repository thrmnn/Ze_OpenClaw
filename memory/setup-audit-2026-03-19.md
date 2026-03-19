# Deep Setup Audit — 2026-03-19

Auditor: Agent 6 (claude-opus-4-6)
Scope: Full workspace, projects, automation, scripts, services

---

## A. Health Scorecard

| Component | Status | One-line reason |
|-----------|--------|----------------|
| OpenClaw Gateway | :green_circle: GREEN | systemd running, Telegram connected, pid 797 active |
| Heartbeat System | :yellow_circle: YELLOW | All 6 checks 23-39h stale — no heartbeat has fired today |
| Memory (QMD) | :yellow_circle: YELLOW | 39 files indexed, 177 vectors, but "Updated 23h ago" despite cron showing "ok 2h ago" — possible silent failure |
| Cron Jobs | :yellow_circle: YELLOW | 9 registered, but Position Radar missing, no memory distillation, no daily auto-commit |
| Scripts (89 total) | :yellow_circle: YELLOW | 5 scripts not executable, 13+ one-time test/setup scripts cluttering the directory |
| Obsidian Vaults | :green_circle: GREEN | All 4 vaults accessible at correct paths, 14 scripts updated to new paths on Mar 18 |
| Google OAuth | :green_circle: GREEN | google-tokens.json refreshed Mar 18 15:27, auto-refresh working |
| Trello MCP | :green_circle: GREEN | Board "Ze Dashboard" connected, synthesis script functional |
| Brave Search | :green_circle: GREEN | Enabled per openclaw status |
| Telegram Channel | :green_circle: GREEN | ON / OK per openclaw status |
| Job Pipeline | :green_circle: GREEN | Active dev — last commit Mar 18 15:50 (fit_gap.py, resume tailoring) |
| Website (Hugo) | :green_circle: GREEN | Active — 3 commits today (Mar 19) fixing build/deploy |
| AI Agency MVP | :green_circle: GREEN | Has app.py, ingest.py, tests/, knowledge-base/, .env — structured and recent |
| Position Radar | :red_circle: RED | Code complete (8 modules, 14 companies) but NO cron, NO automation, NO output files ever generated |
| Mission Control | :yellow_circle: YELLOW | Confusing location: ~/clawd/mission-control has git, ~/mission-control does NOT, ~/projects/mission-control symlinks to wrong one |
| Git Hygiene (clawd) | :yellow_circle: YELLOW | 7 uncommitted/untracked files including MEMORY.md, heartbeat-state, daily logs |

**Summary: 8 GREEN, 7 YELLOW, 1 RED**

---

## B. Broken/Missing Items

### Critical
1. **Position Radar has no cron** — Code is complete but has never produced output. Zero jobs scanned automatically.
2. **Heartbeat checks all stale (23-39h)** — No heartbeat check has fired today (Mar 19). Email last checked Mar 18 09:34, ccusage/drive/memory_search last Mar 17 23:39.
3. **QMD update cron possibly failing silently** — `daily-qmd-update` cron shows status "ok" and "2h ago", but `qmd status` reports "Updated: 23h ago". The cron may be running but not actually updating the index.

### Non-critical
4. **5 scripts missing +x permission**: `check-usage.sh`, `create-ze-main-agent.sh`, `get-real-usage.sh`, `get-windows-host.sh`, `session-usage-monitor.sh`
5. **Mission Control symlink confusion**: `~/projects/mission-control` → `~/mission-control` (NOT a git repo). The actual git repo is `~/clawd/mission-control`. This means `cd ~/projects/mission-control && git status` fails.
6. **7 uncommitted files in ~/clawd**: MEMORY.md, 2 daily logs, active-tasks.json, heartbeat-state.json, obsidian-morning-routine.sh. Last auto-commit was Mar 17 ("Auto: 2026-03-17") — today's didn't fire.
7. **13+ one-time scripts cluttering scripts/**: test-gmail.py, test-drive.py, create-test-doc.py, create-test-doc-v2.py, send-test-email.py, setup-cuda-env.sh, setup-obsidian-mcp.sh, setup-x-api.sh, test-calendar.py, test-gmail-access.py, test-obsidian.sh, test-qmd-cuda.sh, test-smart-spawn.sh, test-ralph.sh
8. **Duplicate scripts**: `today-command.sh` / `today-command-v2.sh`, `create-test-doc.py` / `create-test-doc-v2.py`, multiple OAuth exchange scripts (3 variants)
9. **No daily memory distillation** — AGENTS.md says "Periodically review daily files -> distill into MEMORY.md" but there is no cron or script for this.
10. **No `.gitignore` for credentials/token files** in some projects — `~/clawd/credentials/` is properly gitignored, but `~/projects/mission-control/.env.production` and `.env.local` are tracked.

---

## C. Top 10 Automation Proposals

Ranked by impact/effort ratio (highest first).

### 1. Register Position Radar Cron
**What:** Schedule daily Position Radar scans (morning + evening) to actually use the radar code that's already built.
**How:** `openclaw cron add --name "Position Radar Scan" --schedule "0 9,18 * * * @ America/Sao_Paulo" --command "cd ~/projects/position-radar && python3 radar.py --notify" --target isolated`
**Effort:** S (10 min — the code is done, just needs registration)

### 2. Fix Auto-Commit Cron
**What:** The "Auto: YYYY-MM-DD" commit pattern stopped after Mar 17. Restore daily auto-commit for memory files.
**How:** Check if a cron existed and was removed, or create: `openclaw cron add --name "Daily Auto-Commit" --schedule "55 23 * * * @ America/Sao_Paulo" --command "cd ~/clawd && git add memory/ MEMORY.md && git diff --cached --quiet || git commit -m 'Auto: $(date +%Y-%m-%d)'" --target main`
**Effort:** S (10 min)

### 3. Fix QMD Update Cron
**What:** The `daily-qmd-update` cron reports "ok" but QMD index is 23h stale. Diagnose and fix — likely the cron command doesn't include `qmd embed` after `qmd update`.
**How:** `openclaw cron show 86aa2d13` to inspect the command. Likely needs: `export PATH="$HOME/.bun/bin:$PATH" && qmd update && qmd embed`
**Effort:** S (15 min)

### 4. Heartbeat Freshness Alert
**What:** Add a self-monitoring check: if any heartbeat check is >24h stale, send a Telegram alert. Prevents the current situation where all checks silently went cold.
**How:** Add to the End-of-Day Review cron or create a new lightweight cron that reads heartbeat-state.json and alerts if any timestamp > 24h old.
**Effort:** S (20 min)

### 5. Memory Distillation Cron (Weekly)
**What:** Every Sunday, an agent reviews the week's daily logs and distills key decisions/learnings into MEMORY.md. Currently manual per AGENTS.md.
**How:** `openclaw cron add --name "Weekly Memory Distill" --schedule "0 19 * * 0 @ America/Sao_Paulo" --command "Review memory/2026-*.md from this week. Distill key decisions, learnings, and status changes into MEMORY.md. Remove stale entries." --target main`
**Effort:** M (30 min — needs prompt tuning)

### 6. Fix Mission Control Symlink
**What:** `~/projects/mission-control` currently symlinks to `~/mission-control` (not a git repo). Should point to `~/clawd/mission-control` (the actual git repo).
**How:** `rm ~/projects/mission-control && ln -s ~/clawd/mission-control ~/projects/mission-control`
**Effort:** S (2 min)

### 7. Script Cleanup — Archive One-Time Scripts
**What:** Move 13+ test/setup scripts to `scripts/archive/` to reduce cognitive load. Keep the directory focused on active automation.
**How:** `mkdir -p ~/clawd/scripts/archive && mv ~/clawd/scripts/{test-gmail.py,test-drive.py,create-test-doc.py,create-test-doc-v2.py,send-test-email.py,setup-cuda-env.sh,setup-obsidian-mcp.sh,setup-x-api.sh,test-calendar.py,test-gmail-access.py,test-obsidian.sh,test-qmd-cuda.sh,test-smart-spawn.sh,test-ralph.sh} ~/clawd/scripts/archive/`
**Effort:** S (5 min)

### 8. Position Radar → Trello Integration
**What:** When Position Radar finds new matching jobs, auto-create Trello cards in the job pipeline board with score, company, link.
**How:** Extend `notifier.py` in position-radar to call Trello MCP or the Trello API. Add a `--trello` flag to `radar.py`.
**Effort:** M (1-2h — API integration + card formatting)

### 9. OAuth Token Health Heartbeat Check
**What:** Add a heartbeat rotation item that checks Google OAuth token expiry and proactively refreshes if <1h remaining. Prevents silent auth failures.
**How:** Add to HEARTBEAT.md rotation. Script: read `credentials/google-tokens.json`, check `expiry` field, run `python3 scripts/oauth-refresh-auto.py` if close to expiry.
**Effort:** S (20 min)

### 10. Unified Dashboard Script
**What:** A single `ze-status` command that prints: heartbeat freshness, cron health, git status across all projects, QMD status, Trello summary. One-glance system health.
**How:** Create `scripts/ze-status.sh` that aggregates: heartbeat-state.json timestamps, `openclaw cron list`, `git -C <project> log -1` for each project, `qmd status`, card counts.
**Effort:** M (1h)

---

## D. Quick Wins (fixable in <10 min right now)

### 1. Fix script permissions (2 min)
```bash
chmod +x ~/clawd/scripts/{check-usage.sh,create-ze-main-agent.sh,get-real-usage.sh,get-windows-host.sh,session-usage-monitor.sh}
```

### 2. Fix mission-control symlink (2 min)
```bash
rm ~/projects/mission-control
ln -s ~/clawd/mission-control ~/projects/mission-control
```

### 3. Register Position Radar cron (5 min)
```bash
openclaw cron add --name "Position Radar Scan" \
  --schedule "0 9,18 * * 1-5 @ America/Sao_Paulo" \
  --command "cd ~/projects/position-radar && python3 radar.py" \
  --target isolated
```

---

## E. Inventory

### Cron Jobs (9 registered)
| Name | Schedule | Last Run | Status |
|------|----------|----------|--------|
| Obsidian Vault Maintenance | Daily 15:00 | 1d ago | running |
| End-of-Day Review | Weekdays 17:50 | 2h ago | ok |
| Persist Gateway Logs | Daily 23:00 | 2h ago | ok |
| Daily QMD Update | Daily 07:30 | 2h ago | ok (but see B.3) |
| Obsidian Morning Routine | Daily 08:00 | 2h ago | ok |
| Weekly Review | Friday 18:00 | 3d ago | ok |
| Obsidian SSD Backup | Saturday 10:00 | never | idle |
| Sunday Mini-Review | Sunday 20:00 | never | idle |
| Obsidian Git Backup | Sunday 23:00 | 3d ago | ok |

### Missing Crons
- Position Radar (daily scan)
- Daily auto-commit (memory files)
- Memory distillation (weekly)
- Heartbeat freshness self-check

### Script Count: 89 total
- Shell (.sh): 60
- Python (.py): 27
- JavaScript (.js): 2

### Project Locations
| Project | Path | Git | Last Commit |
|---------|------|-----|-------------|
| clawd (workspace) | ~/clawd | yes | Mar 18 02:15 |
| Job Pipeline | ~/projects/job-pipeline | yes | Mar 18 15:50 |
| Website | ~/projects/website | yes | Mar 19 13:13 |
| AI Agency MVP | ~/projects/ai-agency/mvp | yes (parent) | Mar 18 15:39 |
| Position Radar | ~/projects/position-radar | yes | Mar 18 01:51 |
| Mission Control | ~/clawd/mission-control | yes | Mar 19 13:03 |
| Mission Control (stale) | ~/mission-control | NO git | N/A |

### Services Status
| Service | Status | Notes |
|---------|--------|-------|
| Anthropic API | Active | claude-sonnet-4-6 default, opus-4-6 available |
| Gmail/Drive/Calendar | Active | OAuth auto-refresh, token fresh |
| Trello MCP | Active | Board: Ze Dashboard |
| Brave Search | Active | Web search enabled |
| Obsidian | Active | 4 vaults, PARA structure |
| QMD Memory | Degraded | Index possibly stale (see B.3) |
| Telegram | Active | Bot connected |
| GitHub CLI | Not configured | Needs `gh auth login` |
| Notion | Not configured | Needs API token |
| ElevenLabs TTS | Not configured | Needs API key |

---

*Generated by Agent 6 audit, 2026-03-19 ~15:15 BRT*
