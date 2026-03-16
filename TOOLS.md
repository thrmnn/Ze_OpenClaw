# TOOLS.md - Local Notes

Skills define *how* tools work. This file is for *your* specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:
- Camera names and locations
- SSH hosts and aliases  
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras
- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH
- home-server → 192.168.1.100, user: admin

### TTS
- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

## MCP Servers

### Trello
- **Status:** ✓ Connected via Claude Code MCP
- **Package:** @delorenj/mcp-server-trello
- **Credentials:** `credentials/trello.env` (gitignored)
- **Wrapper:** `credentials/trello-mcp.sh` loads env and runs MCP server
- **Configured:** 2026-01-27

### Filesystem
- **Status:** ✓ Connected via Claude Code MCP
- **Scope:** /home/theo/clawd
- **Package:** @modelcontextprotocol/server-filesystem
- **Configured:** 2026-01-27

### Google Workspace (Gmail + Drive + Calendar)
- **Status:** ✓ Connected via Claude Code MCP AND Python API
- **Package:** @alanse/mcp-server-google-workspace
- **Credentials:** `credentials/google-oauth-client.json` + `credentials/google-tokens.json` (gitignored)
- **Features:** Gmail (read/send), Drive (files), Sheets (57 tools), Calendar
- **OAuth:** Completed 2026-01-27, tokens auto-refresh
- **Configured:** 2026-01-27
- **Python API Usage:**
  ```bash
  # Activate venv-google for Gmail/Drive/Calendar API access
  cd ~/clawd && source venv-google/bin/activate
  # Then use google.oauth2.credentials and googleapiclient
  ```
- **Email:** zeclawd@gmail.com
- **Verified:** 2026-01-30 (sent test email successfully)

---

## QMD (Quick Markdown Search)

**Token Optimization Tool** - Local semantic search for markdown files

### Setup
- **Status:** ✓ Installed & Configured
- **Binary:** `~/.bun/bin/qmd`
- **Index:** `~/.cache/qmd/index.sqlite`
- **Collections:**
  - `memory` → `~/clawd/memory/**/*.md` (daily logs)
  - `workspace` → `~/clawd/*.md` (SOUL.md, USER.md, etc.)
- **Configured:** 2026-01-31

### Quick Usage
```bash
# Always add bun to PATH first
export PATH="$HOME/.bun/bin:$PATH"

# Search (keyword)
qmd search "email decisions" -n 5

# Semantic search
qmd vsearch "how to send emails"

# Best quality (hybrid + reranking)
qmd query "CERN application" -n 3 --min-score 0.3

# Get specific file
qmd get memory/2026-01-31.md

# Get multiple files
qmd multi-get "memory/2026-01-*.md" --json
```

### Token Savings
- **Before:** Load entire MEMORY.md (~5000 tokens) for every recall
- **After:** Search + retrieve 3 relevant snippets (~300 tokens)
- **Reduction:** 75-90% fewer tokens per memory query

### Documentation
Full usage guide: `docs/QMD-USAGE.md`

### Maintenance
```bash
# Re-index after adding files
qmd update

# Re-embed after major changes
qmd embed -f

# Check status
qmd status
```

---

## OpenClaw Skills (Installed)

### GitHub (🐙)
- **Status:** ✓ Installed (needs auth)
- **CLI:** `gh` (GitHub CLI)
- **Setup:** Run `gh auth login` once
- **Use for:** Issues, PRs, repos, CI runs
- **Installed:** 2026-02-09

### Notion (📝)
- **Status:** ⚙️ Installed (needs API token)
- **Credentials:** `credentials/notion.env` (create if needed)
- **Get token:** https://www.notion.so/my-integrations
- **Use for:** Pages, databases, blocks
- **Installed:** 2026-02-09

### Trello (📋)
- **Status:** ✓ Production System v2 (Obsidian-first)
- **Credentials:** `credentials/trello.env` ✓
- **Board:** "Zé Dashboard" (Board ID: 699dc91ad27a2301f3acc5f1)
- **Philosophy:** Trello = execution dashboard, Obsidian = source of truth
- **Workflow Lists (Required):**
  - **Inbox** - Unsorted incoming tasks
  - **Today** - Max 5 tasks (today's focus)
  - **Next Actions** - Ready to work
  - **In Progress** - Max 3 tasks (active work)
  - **Waiting / Blocked** - Dependencies
  - **Projects** - Project overview cards
  - **Done** - Completed (archive weekly)
- **Card Format:**
  - Title: Verb + Outcome
  - Description: Project name + Obsidian link + optional checklist
- **Use for:** Visual task management, daily prioritization
- **Installed:** 2026-02-09
- **Updated:** 2026-03-16 (v2: Obsidian-first system)
- **Custom Commands:**
  - `/today` - Extract tasks from Obsidian, prioritize, update Trello
  - `/review` - Weekly review, archive, refresh Next Actions
  - Scripts: `~/clawd/scripts/today-command-v2.sh`
- **Documentation:** `Resources/Productivity System - Obsidian + Trello.md`
- **Rules:**
  - Max 5 in Today, 3 in Progress
  - One Next Action per project
  - Tasks originate from Obsidian
  - Archive Done cards weekly

### Obsidian (💎)
- **Status:** ✅ Production Ready - Second Brain Active
- **Vault Path (WSL):** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault`
- **Vault Path (Windows):** `C:\Users\theoh\OneDrive\Documents\Obsidian Vault`
- **Config File:** `/mnt/c/Users/theoh/AppData/Roaming/obsidian/obsidian.json`
- **Structure:** PARA method (Projects/Areas/Resources/Archive)
- **Backup:** OneDrive (active), Git (ready), SSD (ready)
- **Installed:** 2026-02-09 | **Configured:** 2026-03-14

**Scripts:**
- `~/clawd/scripts/obsidian.sh` - Main helper (create/search/read/append)
- `~/clawd/scripts/obsidian-trello-sync.sh` - Sync Trello NOW to daily notes ✅
- `~/clawd/scripts/obsidian-backup-git.sh` - Git backup automation (needs setup)
- `~/clawd/scripts/obsidian-backup-ssd.sh` - Physical SSD backup (needs setup)

**Quick Commands:**
```bash
# List all notes
bash ~/clawd/scripts/obsidian.sh list

# Search by name
bash ~/clawd/scripts/obsidian.sh search "meeting"

# Search content
bash ~/clawd/scripts/obsidian.sh search-content "todo"

# Create note
bash ~/clawd/scripts/obsidian.sh create "Folder/Name" "# Content"

# Read note
bash ~/clawd/scripts/obsidian.sh read "Folder/Name"

# Append to note
bash ~/clawd/scripts/obsidian.sh append "Folder/Name" "More content"

# Sync Trello to today
bash ~/clawd/scripts/obsidian-trello-sync.sh
```

**Documentation in Vault:**
- `Resources/How to Use This Vault` - Complete guide
- `Resources/How to Work with Zé` - Communication methods
- `Resources/Backup Strategy` - 3-2-1 backup setup
- `Inbox/INTERVIEW - Vault Setup Questions` - ⏳ Awaiting answers
- `Inbox/TEMP - Git and SSD Backup Setup Plan` - ⏳ Awaiting decisions

### Sag / ElevenLabs TTS (🗣️)
- **Status:** ⚙️ Installed (needs API key)
- **Credentials:** `credentials/elevenlabs.env` (create if needed)
- **Get key:** https://elevenlabs.io/app/settings/api-keys
- **Use for:** Voice output, story narration
- **Installed:** 2026-02-09

---

## AI Agency Project

### Auto-Update Command
**Script:** `~/clawd/scripts/ai-agency-update.sh`

**What it does:**
- Cleans unnecessary/duplicate files from AI Agency folder
- Keeps only: EXECUTION ROADMAP.md, project.md, tasks.md, notes.md
- Shows current project status

**Usage:**
```bash
bash ~/clawd/scripts/ai-agency-update.sh
```

**When to run:**
- After creating new planning docs
- Before starting work sessions
- Weekly cleanup

**Structure:**
- **EXECUTION ROADMAP.md** - Source of truth (strategy + 90-day plan)
- **tasks.md** - Current week actions
- **project.md** - Quick overview
- **notes.md** - Ideas and research

---

Add whatever helps you do your job. This is your cheat sheet.

---

## Mission Control Dashboard

### Status
- **Status:** ⚠️ Partially Working - Activity logging works, mutations need debugging
- **URL:** https://mission-control-ruby-zeta.vercel.app/
- **Backend:** Convex (real-time database + API routes)
- **Deployed:** 2026-02-24
- **Last Updated:** 2026-02-25
- **Working:** Activity logging (POST/GET)
- **Not Working:** Agent updates, spawn requests (under investigation)

### Features
- Real-time agent status monitoring
- Activity logging and history
- Spawn request management
- Content pipeline tracking
- Project portfolio
- Token usage tracking (planned)

### API Endpoints
- `POST /api/spawn-request` - Create agent spawn requests (use Convex CLI instead)
- `POST /api/activity` - Log activity ✅ Working
- `GET /api/activity` - Fetch recent activity ✅ Working
- `POST /api/agent-update-direct` - Update agent status/stats ✅ Working

### Testing from Telegram
Run: `test mission control` or `run bash ~/clawd/scripts/mission-control-test.sh`

### Integration Scripts
- `scripts/mission-control-test.sh` - Full integration test
- `scripts/mission-control-log.sh` - Quick activity logger

### Documentation
- `mission-control/TELEGRAM-TESTING.md` - Mobile testing guide
- `mission-control/INTEGRATION-STATUS.md` - Full integration status
- `mission-control/DEPLOYMENT-CHECKLIST.md` - Deployment progress

