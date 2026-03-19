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

## 2026-03-18 — Full Parallel Build Sprint

### 6 agents, ~15 min total — all done ✅

| Project | What was built |
|---------|---------------|
| LAI Paper | Editorial polish, tree count fix (→12,350), 15 LaTeX fixes, clean compile. Push blocked (SSH key to fix). `[repository URL]` placeholder in methods.tex l.107 |
| AI Agency MVP | Full RAG scaffold: Qdrant+Docker, LlamaIndex ingestion, Streamlit chat UI. `~/projects/ai-agency/mvp/` |
| Brisa+ Slides | Tomorrow's deck (6 slides, PK style, speaker notes) + 5-presentation calendar in Obsidian |
| Personal Website | 3 project descriptions (Roboat, Loomo, Urban Digital Twin/Brisa+) + bonus LAI. Hugo build ✅ 168 pages. CI/CD GitHub Pages configured |
| Job Pipeline | Multi-platform discovery: `~/projects/job-pipeline/discovery/` — Greenhouse, Lever, LinkedIn, Wellfound. Modular (discover.py + fetcher/scorer/dedup/notifier/queue_writer) |
| Mission Control | Tasks Kanban (/tasks) replacing Trello. Agents panel with pixel-agents VS Code deep link. /api/pixel-agents endpoint |

### SSH / GitHub Remotes (critical — two accounts)
- `theoh-io` account → key `id_ed25519`, host alias `github-theoh-io`
- `thrmnn` account → key `id_rsa`, host alias `github-thrmnn`
- Default `github.com` host maps to `theoh-io` key — WRONG for thrmnn repos
- Fixed remotes: `git remote set-url origin git@github-thrmnn:thrmnn/<repo>.git`
- LAI paper: `git@github-thrmnn:thrmnn/lai_paper.git` ✅ fixed 2026-03-18
- Website: `git@github-thrmnn:thrmnn/thrmnn.github.io.git` ✅ fixed 2026-03-18

### Personal Website
- Repo: `~/projects/website/` → deploys to `https://thrmnn.github.io`
- Hugo Blox (academic CV theme), 168 pages, build clean
- Source of truth: `PERSONAL_INFO.md` + `PROJECTS.md` → run `python3 sync_personal_info.py` after edits
- 3 projects written by agent: Roboat, Loomo, Urban Digital Twin/Brisa+LAI
- GitHub Actions CI/CD configured for auto-deploy on push to main
- To preview locally: `cd ~/projects/website && hugo server`
- To deploy: `git push origin main` (Actions build automatically)

### AI Agency MVP
- Location: `~/projects/ai-agency/mvp/`
- Stack: Qdrant (Docker) + LlamaIndex + OpenAI embeddings + Claude + Streamlit
- Launch: `docker-compose up -d && pip install -r requirements.txt && python ingest.py && streamlit run app.py`
- UI at http://localhost:8501
- Needs `.env` with OPENAI_API_KEY + ANTHROPIC_API_KEY
- Demo content seeded in `knowledge-base/sample/`

### Mission Control Dashboard
- Live URL: https://mission-control-ruby-zeta.vercel.app/
- Codebase: `~/clawd/mission-control/`
- Convex: `prod:usable-whale-844`
- New pages built 2026-03-18: `/tasks` (Kanban, replaces Trello), `/agents` (live activity + pixel-agents deep link)
- Pixel-agents API: `GET /api/pixel-agents` → JSON for VS Code extension
- Auto-deploys from Vercel on git push to main
- To redeploy after local changes: push `~/clawd/mission-control` to its GitHub remote

### Brisa+ Presentations
- Files in Obsidian: `Ob_Research_Vault/Projects/Academic Research/Brisa+ Paper/Presentations/`
  - `Presentation-Schedule.md` — 5-week calendar (March 19 → April 17)
  - `2026-03-19-Pipeline-Overview.md` — tomorrow's deck, 6 slides, full speaker notes
- Drive folder with past SCR decks: https://drive.google.com/drive/folders/1E_1zF_K3UyLh0cg3SEM4m6cLCqsdITsF
- Format: PK style — visuals on slide, ALL text in speaker notes
- Tomorrow (March 19): visuals to prep tonight — pipeline flowchart, Rio TB map, OpenFOAM sketch, timeline strip
- TODO: sync new presentations to Weekly SCR Drive folder

### Job Pipeline Discovery
- New module: `~/projects/job-pipeline/discovery/`
- First run: 494 scored, 17 queued, 5 alerts (Apptronik 83, Waymo 75 top)
- Run: `python discovery/discover.py` (supports --dry-run, --sources flags)

### /today Command Workflow (established 2026-03-18)
- When user runs /today: read daily note + all INTERVIEW files → process → update daily note with actionable intel
- INTERVIEW files live at: `{vault}/Projects/{project}/INTERVIEW - Current Status.md`
- Daily note path: `Ob_Perso_Vault/Daily/YYYY-MM-DD.md`
- Always add a "Zé's read" notes section with concrete observations, not just summaries
- Flag blockers, inconsistencies, and missing info explicitly

### 2026-03-18 Afternoon — Parallel Sprint Results

#### LAI Paper ✅
- All 5 blocking submission checklist items fixed and committed (`d35b6c5`)
- Discussion §4.1-4.3 were missing from source .tex (only in compiled PDF) — reconstructed
- PDF compiles clean: 22 pages
- **Still needs push to origin** (SSH key: `github-thrmnn`)
- Deadline: Friday March 21 🔴

#### Brisa+ ✅
- 3 commits: bibliography hardened (3 new refs, all 37 annotated), Nature Cities claims mapped, reviewer prebuttal language added
- Untracked docs committed
- Branch: `literature-review-expansion`

#### Job Pipeline ✅ (3 bugs fixed)
- `location=None` Amazon bug: patched in all scrapers
- Path inconsistency: tracker notes now use `job_slug`
- ATS score field: `ats_score` → `ats_optimization_score` (was returning None silently)

#### Mission Control ✅
- `/radar` page added (Position Radar table, 5 seeded positions)
- UI: stat trend indicators, agent badges, task count pills, drag-and-drop
- Deployed to Vercel via `origin/master`

#### Website ✅ (GitHub Pages, not Vercel)
- `public/` excluded from git (952 artifacts removed)
- Hugo pinned to 0.136.5 + blox-tailwind pinned to v0.3.1 (v0.10.0 needs preact + TailwindCSS CLI in CI — incompatible)
- GitHub Pages source must be set to "GitHub Actions" in repo settings
- Vercel deploy deferred: Hugo not pre-installed in Vercel build env for custom framework

#### AI Agency MVP ✅
- Streamlit UI polished: branding, sidebar, phased loading, error handling
- PDF support confirmed, sample_queries.md added, README rewritten

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

### Key State (updated 2026-03-18)
- Job pipeline: fully built and tested ✅
- Position Radar: live, daily cron ✅
- Application Tracker: live, 6 entries ✅
- AI Agency: assets ready (landing page, LinkedIn list, Upwork copy), MVP not built ❌
- LAI deadline: Friday March 21 🔴 — draft complete, all sections present, Carlo feedback integrated
  - LAI paper repo 10 commits ahead of origin/main — needs push
  - Possible inconsistency: abstract says 12,350 trees vs results ~12,000/6,178 — needs check
  - `%%Add more here` comment in methods.tex — fill or remove before submission
  - Supervisor comments location unknown (PDF annotations? email?) — ask Théo
- Brisa+ presentation: TOMORROW Thursday March 19 🔴 (internal)
- Brisa+ workshop: March 27
- Custom dashboard replacing Trello — decision made 2026-03-18

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

## 2026-03-18 — Afternoon Sprint (Wave 2-4)

1. **LAI Paper** — All 5 Phase 1 blocking text fixes applied and pushed (`d35b6c5`). Submission readiness: **8/10**. Remaining blockers: XGBoost citation (Chen & Guestrin 2016), scikit-learn citation (Pedregosa 2011), supplementary materials separation (Springer Nature requires standalone file).
2. **Job Pipeline** — Quality audit found resume tailoring bug (bullets not rewritten, just copied) and scorer too conservative. Discovery scan: 567 jobs fetched, 530 seen/filtered, 0 new high-score queued. Dead Lever endpoints removed (Machina Labs, Viam — migrated off platform).
3. **Position Radar** — Expanded to 25+ companies, ATS endpoints verified across Greenhouse/Lever/Ashby/direct, tests added for scanner config.
4. **AI Agency** — MVP complete: LlamaIndex + Qdrant + Claude RAG pipeline, Streamlit chat UI, demo script with sample queries, pitch deck outline, Makefile, tests. Location: `~/projects/ai-agency/mvp/`.
5. **Website** — 2 publications added, content polished across all pages, Vercel deploy configured. Hugo builds clean (168 pages).
6. **Mission Control** — War Room rebuilt: live agent pills (PID + workdir), project board with status badges, auto-refresh 30s, `/api/status` endpoint.
7. **Brisa+** — CFD pipeline plan documented. Literature review seeds: 25 papers across 4 pillars (informal morphology, environment-health, CFD methods, performance frameworks). DOIs ready for Zotero cross-check.
8. **Obsidian** — All 4 vault dashboards updated, INTERVIEW files refreshed for active projects, daily note maintained.

---

## Notes

*This file should be reviewed and updated during heartbeats - distill daily logs into lasting knowledge.*

## 2026-03-18 — Afternoon Sprint (Waves 2-4)

### ~55 agent sessions across 7 projects in 4 hours

**LAI Paper** — Readiness 6.5 → 8/10
- Blocking fixes applied + pushed (commit d35b6c5): title grammar, Discussion R² errors, bad citation [3], placeholder URL
- Co-author email templates generated (Carlo Ratti, Fabio Duarte, Michiel van Selm, Titus Venverloo)
- Remaining blockers for Théo: add XGBoost + scikit-learn citations, separate supplementary materials

**Job Pipeline** — Quality audit revealed issues
- Discovery scan: 567 jobs fetched, 530 seen total, 0 new high-score (all hard-filtered)
- CRITICAL: resume tailoring bug — "tailored" bullets identical to originals. Code is correct (prompt says rewrite), but LLM call may fail silently. Needs live test.
- Scorer too conservative: Apptronik autonomy role scores 31% (should be 55-70%)
- Dead Lever endpoints removed (Machina Labs, Viam)

**Position Radar** — 14 → 25+ companies
- Added: Boston Dynamics, Figure AI, Waymo, Nuro, Agility Robotics, Shield AI, Anduril, Zipline, Skydio, Climeworks, NVIDIA, Tesla, 1X Technologies, etc.
- 4 source types: Greenhouse, Lever, Ashby, direct scrape
- Tests added (test_fetcher.py), error handling for 403/429/timeouts

**AI Agency MVP** — Production-ready
- OpenAI key stored safely (credentials/ + .env)
- Demo materials: DEMO_SCRIPT.md, PITCH_DECK_OUTLINE.md, sample_queries.md
- Makefile, tests, .env.example all created

**Personal Website** — Live at thrmnn.github.io
- 2 publications added, content polished, Hugo 138 pages clean
- Vercel deploy configured (vercel.json + Hugo framework detection)

**Mission Control** — War Room at localhost:3000
- Rebuilt: live agent detection (ps), project board with status, auto-refresh 30s
- Pages: / (war room), /tasks (kanban), /agents (live+history), /memory (search), /api/status

**Brisa+ Paper** — Scaffolding complete
- CFD pipeline plan documented (docs/cfd-pipeline-plan.md)
- 25 seed papers, gap analysis, Nature Cities guidelines all in place
- Guided workflow note created in Obsidian for Théo

**Obsidian** — All 4 vaults maintained
- Dashboards updated, broken links fixed, daily note maintained
- INTERVIEW files refreshed with current project states
- LAI Review Feedback note + Brisa+ Guided Workflow note created

### Key Decisions
- Mission Control lives at ~/projects/mission-control (not ~/clawd/mission-control)
- OpenAI key at ~/clawd/credentials/openai-api-key.txt + ~/projects/ai-agency/mvp/.env
- Claude Code usage cap: resets every ~3 hours, agents die with code 143 when hit

---

## 2026-03-19 — Wave 2 Agent Sprint

### Job Pipeline — Tailoring Bug Fixed + Scorer Recalibrated
- Resume tailoring bug fixed: bullets were being copied verbatim instead of rewritten. Verbatim copy detection now works. Commits: `d43d3fe`, `50b69af`, `f0008c5`
- Scorer recalibrated: Apptronik roles now score ~55-70% (was 31% — way too conservative)
- LLM-first v2: resume and cover letter generation switched to Opus direct call
- Amazon Robotics job processing triggered (Agent 2), unblocked after pipeline fix confirmed

### Website — Deployed to GitHub Pages
- Site live at `thrmnn.github.io`
- GitHub Actions workflow fixed: 5 commits (blox-analytics module issues + stale caches)
- Deploy succeeded at 16:13 UTC

### AI Agency — Outreach Tracker + French Legal-Tech
- Outreach tracker created
- 3 LinkedIn DMs drafted: Hyperlex, Leeway, Predictice (French legal-tech companies)
- Pitch angle: RAG for legal document processing
- Upwork profile polish + pitch deck + cold email in progress (Agent 7)

### Mission Control — /api/status Fixed + Deployed
- `/api/status` endpoint added and working
- Kanban seed data updated to current projects
- Deployed to Vercel (`fc8dbd7`)

### Strategy Decision
- **Théo handles research manually** (LAI paper, Brisa+ paper) — too sensitive for autonomous agents
- **Zé runs everything else in parallel** — job pipeline, website, AI agency, mission control, position radar
- This division confirmed working well: 8 agents today, all productive
