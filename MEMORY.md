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

---

## Important Decisions

### 2026-01-27
- Created separate Gmail (zeclawd@gmail.com) for document sharing
- Credentials secured in gitignored credentials/ folder
- Usage monitoring: Alert at 70%, critical at 95%
- Heartbeat rotation: Usage always, Email/Trello/Drive cycled

---

## Ongoing Tasks

### Active Projects (from Trello NOW)
1. Clawdbot setup (in progress)
2. Presentation RM (6 checklist items)
3. Job Application: CERN (CV, motivation letter)

### Deferred Setup Items
- Audio transcription (Whisper - large dependencies issue)
- Multilingual interface configuration

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

### Obsidian Integration ✅
- **Vault:** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault`
- **Helper Script:** `~/clawd/scripts/obsidian.sh`
- **Structure:** PARA method (Projects, Areas, Resources, Archive)
- **Capabilities:**
  - Create notes programmatically from Telegram
  - Search vault (name + content)
  - Daily note automation
  - Knowledge graph with [[wikilinks]]
- **Integration:** Ready for co-working loop with Trello + Memory + QMD
- **Documentation:** `~/clawd/docs/OBSIDIAN-SECOND-BRAIN.md`

### Key Decision
- **Two-tier memory system:**
  - System logs: `~/clawd/memory/` (raw, for QMD search)
  - Knowledge base: Obsidian vault (curated, human-readable)
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
