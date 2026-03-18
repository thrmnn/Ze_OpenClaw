# MEMORY.md - Long-Term Memory

*Curated memories, decisions, and learnings. Daily logs are in memory/YYYY-MM-DD.md*

---

## 2026-01-27 - First Day

### Identity & Setup
- Defined as Zé (Zézinho) - calm, sharp operator with relaxed confidence
- Core workspace: /home/theo/clawd
- Established workspace files: SOUL.md, IDENTITY.md, USER.md, TOOLS.md, AGENTS.md

### Services Connected
1. **Telegram:** @Tzinho_lclclawdbot - main interface
2. **Trello:** Board "Zé Dashboard" - task management (switched 2026-02-24)
3. **Google Workspace:** zeclawd@gmail.com - dedicated email/drive for shared documents

### MCP Servers Configured
- Filesystem MCP (workspace access)
- Trello MCP (board/card management)
- Google Workspace MCP (Gmail + Drive + Sheets)

### Key Learnings
- **Security:** Always put credentials in `credentials/` folder (gitignored)
- **Context Management:** Display usage percentage with every response
- **Memory Strategy:** Daily logs (raw) → MEMORY.md (curated)
- **OAuth in WSL:** Manual flow needed (can't open browser)

### User Preferences
- Multilingual: French/English/Portuguese
- Values: Clarity, efficiency, low friction
- Expects: Observe first, act decisively, minimal questions
- **After completing major task batches:** Short, elegantly condensed prose summary — not bullet reports

---

## Important Decisions

### 2026-01-27
- Created separate Gmail (zeclawd@gmail.com) for document sharing
- Credentials secured in gitignored credentials/ folder
- Usage monitoring: Alert at 70%, critical at 95%
- Heartbeat rotation: Usage always, Email/Trello/Drive cycled

---

## Ongoing Tasks

### Active Projects (as of 2026-03-17)
1. **Job Application Pipeline** — multi-agent LangChain system at `~/projects/job-pipeline/`, production-ready. 4 URLs queued in JOB_QUEUE.md (2x CERN, Amazon Robotics, Singapore Tech). Not yet triggered.
2. **Position Radar** — architecture complete (Obsidian), not yet built. Design at `Ob_Business_Vault/Projects/Job Application Pipeline/Position Radar - Architecture.md`
3. **AI Agency** — execution roadmap done, landing page copy done, LinkedIn target list done (50 companies), Upwork profile copy done. MVP build pending.
4. **LAI Paper** — deadline Friday March 21 🔴
5. **Personal Website** — 70% complete, blocked on photos/screenshots + resume PDF

### Deferred
- Audio transcription (Whisper - large dependencies)
- Brisa+ paper setup (in progress)

---

## 2026-03-18 - Full Job Pipeline Stack Built

### Script Vault Path Migration
- **14 scripts** fixed: `"Obsidian Vault"` → `"Obsidian Vaults/Ob_*_Vault"`
- Committed: `8b74f85`

### Job Application Stack — Full Architecture (built tonight)

```
Position Radar         → scans 15 companies daily (Greenhouse/Lever APIs)
  ~/projects/position-radar/radar.py
  Scoring: 0-100 rubric, alert threshold ≥70, cron 9am Brazil
  Top match: Apptronik Senior Autonomy SW Eng = 83/100

JOB_QUEUE.md           → URL queue in Ob_Business_Vault
  Auto-populated by Position Radar when score ≥65
  Manual URLs also supported

process_queue.py       → batch processor (reads queue, runs pipeline per job)
  ~/projects/job-pipeline/process_queue.py
  Uses: ~/miniconda3/bin/conda run -n job-pipeline python process_queue.py

7-Agent Pipeline       → per job: fit analysis + resume tailoring + narratives + audit
  LLM: claude --print -p (fixed 2026-03-18, real scores now)
  Profile: data/theo-profile.json

Output per job:
  - application.json (fit score, tailored bullets, motivation, audit)
  - resume.pdf (fpdf2, ATS-safe single column)
  - cover_letter.pdf (professional letter format)
  - Saved to: Ob_Business_Vault/Projects/Job Application Pipeline/results/{slug}/
  - Uploaded to: Google Drive → Job Applications/2026-03/{Company} — {Role}/

Application Tracker    → SQLite at ~/projects/job-pipeline/tracker.db
  Tables: applications, rounds, documents
  CLI: conda run -n job-pipeline python -m tracker.cli status
  Obsidian notes: .../Job Application Pipeline/applications/{slug}/index.md
  Daily digest cron: 9am → Telegram (silent if no active apps)

Task Ledger            → ~/clawd/memory/active-tasks.json
  CLI: bash ~/clawd/scripts/task-ledger.sh status
  Pretty: python3 ~/clawd/scripts/task-status.py
```

### Active Applications (as of 2026-03-18)
| Company | Role | Fit | Status |
|---------|------|-----|--------|
| Apptronik | Senior Autonomy SW Eng | 32% | to_apply |
| Apptronik | SW Eng — Dexterity | 25% | to_apply |
| Apptronik | RL Engineer | 26% | to_apply |
| Amazon | Robotics ME (Frontier AI) | 50% | to_apply |
| Singapore Tech | Research Eng (Multimodal AI) | 35% | to_apply |
| CERN | Industrial Automation Eng | 15% | to_apply |

### OAuth Status ✅
- Google Drive + Calendar confirmed working (tested 2026-03-18)
- Real Drive upload wired into pipeline

### Key State
- Job pipeline: fully built and tested ✅
- Position Radar: live, daily cron ✅
- Application Tracker: live, 6 entries ✅
- AI Agency: assets ready (landing page, LinkedIn list, Upwork copy), MVP not built ❌
- LAI deadline: Friday March 21 🔴 (3 days)

---

## 2026-02-24 - Trello Migration & Mission Control

### Trello Board Switch
- **Old board:** "Zizou framework" (access revoked)
- **New board:** "Zé Dashboard" (ID: 699dc91ad27a2301f3acc5f1)
- **Structure:** French-language lists
  - Sprint En Cours (Current Sprint) - active tasks
  - En Cours (In Progress)
  - En Attente (Waiting)
  - À Venir (Upcoming)
  - Fait (Done)
  - Plus idea boxes, resources, wins tracker
- **Scripts updated:** trello-synthesis.sh, trello-quick-actions.sh
- **Purpose:** Better organized workflow with sprint-based task management

### Mission Control Status
- Development: 60% complete (code 100%, deployment pending)
- Convex database: Connected and seeded
- Dev server: Running locally at localhost:3000
- Next steps: GitHub push + Vercel deployment

---

## 2026-03-14 - OpenClaw Doctor Fixes & Obsidian Second Brain

### Doctor Fixes
- **Memory Search:** Disabled built-in (using QMD instead) - cleared all embedding warnings
- **Telegram Group Policy:** Changed to "open" to accept group messages
- **Node Runtime:** NVM warning acknowledged (functional, manual fix available if needed)

### Obsidian Integration ✅ (4 vaults since 2026-03-17)
- **Vaults:** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/`
  - `Ob_Research_Vault` — academic papers, CERN, science
  - `Ob_Business_Vault` — jobs, AI agency, personal website
  - `Ob_Robotics_Vault` — Zé system, productivity, tools
  - `Ob_Perso_Vault` — daily notes, health, habits, trading
- **Helper Script:** `~/clawd/scripts/obsidian.sh --vault research|business|tech|personal`
- **Structure:** PARA method in all 4 vaults (66 notes migrated)
- **All scripts updated** to point to correct vault paths (2026-03-18)

### Key Decision
- **Two-tier memory system:**
  - System logs: `~/clawd/memory/` (raw, for QMD search)
  - Knowledge base: Obsidian vaults (curated, human-readable)
  - Separation: Machine context vs human knowledge

### LAI Paper Automated Workflow ⚠️ CRITICAL
- **Repository:** `/home/theo/lai_paper` (Git, synced with origin/main)
- **Type:** Professional academic manuscript (Springer Nature format)
- **Main File:** `draft/sn-article.tex`
- **Safety Protocols:** MANDATORY before ANY edit
  - Pre-flight check (clean working tree, synced remote)
  - Backup before changes
  - User approval required for ALL content changes
  - Show diff before applying
  - Commit immediately after change
  - Push to GitHub after commit
- **Constraints:**
  - NEVER modify scientific claims without approval
  - NEVER change citations/figures without approval
  - ALWAYS read CLAUDE.md editing guidelines first
  - ALWAYS use safety-protocols.sh workflow
- **Scripts:**
  - `~/clawd/scripts/lai-paper-workflow.sh` (automation)
  - `~/clawd/scripts/lai-paper-safety-protocols.sh` (safety)
- **Documentation:** `Projects/Academic Research/LAI Paper/CRITICAL - Safety Protocols.md`

**This is real academic work - extreme caution required.**

### Academic Paper Management System 📚
- **System Guide:** `Resources/Academic Paper Management System.md`
- **Philosophy:** Separation of concerns (Git = source, Obsidian = management)
- **Structure:** Every paper follows standard folder template
  - Index.md (hub)
  - Feedback Log.md (revisions)
  - CRITICAL - Safety Protocols.md (mandatory rules)
  - Workflow Setup.md (automation guide)
  - Quick Reference.md (commands)
- **Safety Guardrails:** Universal rules applied to all papers
- **Scalability:** Template-based, scales from 2 → 10+ papers
- **Active Papers:**
  1. LAI Paper (`/home/theo/lai_paper`) ✅ Fully configured
  2. Brisa+ Paper (`/home/theo/brisa_paper`) ⚙️ Setup in progress

---

## Notes

*This file should be reviewed and updated during heartbeats - distill daily logs into lasting knowledge.*
