# Infrastructure Overhaul — 2026-04-02

> Session log of all changes made during the deep system audit and restructure.

---

## What Was Done Today

### Memory Restructure ✅
- MEMORY.md rewritten: 14,851 → 4,154 chars (72% reduction)
- New architecture: lean hot-context file + topic files for everything else
- 8 topic files created in `~/clawd/memory/topics/`:
  - `project-job-pipeline.md`
  - `project-website.md`
  - `project-mission-control.md`
  - `project-ai-agency.md`
  - `system-openclaw-config.md`
  - `system-github-ssh.md`
  - `rules-academic-papers.md`
  - `archive-2026-03.md`

### QMD Vault Indexing ✅
- Updated `~/.config/qmd/index.yml` from 2 → 6 collections
- Added 4 vault collections: vault-research, vault-business, vault-perso, vault-robotics
- Total indexed: 269 files (11 workspace + 51 memory + 207 vault files)
- Index size: 6.5MB, 423 chunks embedded
- Direct QMD queries work perfectly — `memory_search` tool still broken (see Pending)

### SSH Keys for GitHub ✅
- Generated `~/.ssh/github_theoh` (ed25519) → `theoh-io` account
- Generated `~/.ssh/github_thrmnn` (ed25519) → `thrmnn` account
- `~/.ssh/config` created with both host aliases
- Both keys uploaded to GitHub and authenticated

### clawd Git Init + Remote ✅
- `~/clawd` initialized as git repo
- Remote: `git@github-thrmnn:thrmnn/Ze_OpenClaw.git`
- 255 files committed, pushed to `master`
- Miniforge installer excluded from tracking
- Daily Auto-Commit cron keeps it synced

### Cron Audit ✅
- 29 crons audited, classified: 15 DUMB / 2 SEMI / 12 SMART
- Full audit table saved in session

### Cron Cleanup ✅ (partial)
- Deleted 5 redundant crons:
  - Pre-Workout Meal Reminder (redundant with Morning Health Brief)
  - Friday Clean 🧹
  - Wednesday House Check 🏠
  - Sunday Grooming Check 💈
  - Weekly Meal Prep Reminder
- Added 1 consolidated cron:
  - `Weekly Life Admin 🏠` — Sunday 10:00 Brazil, covers all 4 lifestyle checklists
- Final cron count: **24** (was 29)

---

## What's Pending

### 🔴 CRITICAL: memory_search tool fix
- Tool is hardcoded to query `memory-root-main` collection only
- Timeout set to 15s — too tight, causes timeouts on CPU-based embedding search
- Config found at: `~/.openclaw/openclaw.json` → `memory.qmd`
- Fix needed:
  - `timeoutMs`: 15000 → 45000
  - `paths`: add vault paths so tool searches all 6 collections
- **Status: awaiting Théo approval before applying**

### OpenClaw Update
- Running 2026.3.13, latest available: 2026.3.23-2
- Run: `openclaw update`

### Cron Intelligence Rewrite
- 15 DUMB crons that could be upgraded to read state and reason
- Priority targets: Health Morning Log, Monthly Health Admin, Anniversary crons
- Plan: convert static prompts to context-aware ones that read relevant files

### VPS Swap
- No swap configured — OOM risk with gateway at ~1.8GB RAM
- Fix: `sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`

### Anthropic API Credits
- Key `sk-ant-api03-...` has zero credits
- Python SDK calls fail — workaround is Claude CLI (OAuth token)
- Fix: add credits at console.anthropic.com/billing

### x-cache cleanup in git
- `memory/x-cache/*.json` blobs still tracked — adds bulk to repo
- Fix: add `memory/x-cache/` to `.gitignore` + `git rm --cached`

---

## 6-Fix Priority List

| # | Fix | Status |
|---|-----|--------|
| 1 | memory_search timeout + vault collections | ⏳ Awaiting approval |
| 2 | OpenClaw update | 🔲 Not started |
| 3 | Cron cleanup | ✅ Done (5 deleted, 1 added) |
| 4 | VPS swap | 🔲 Not started |
| 5 | x-cache git cleanup | 🔲 Not started |
| 6 | Cron intelligence rewrite | 🔲 Planned |

### TODO — Session Claude Code (prochaine)
- [ ] Fixer OAuth Google Calendar write scope (actuellement readonly)
  - Re-faire le flow avec `calendar.events` scope
  - Tester création d'événement depuis Telegram
