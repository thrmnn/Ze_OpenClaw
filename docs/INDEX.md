# Zé Workspace - Master Index

**Last Updated:** 2026-03-16  
**Quick Access:** Use aliases! (`cw`, `otd`, `aar`, etc.)

---

## 🏠 Core Configuration Files

**Location:** `~/clawd/`

| File | Purpose | Alias |
|------|---------|-------|
| `SOUL.md` | Zé's personality and vibe | `soul` |
| `USER.md` | Your information (Théo) | `user` |
| `IDENTITY.md` | Zé's identity details | - |
| `MEMORY.md` | Long-term curated memory | `mem` |
| `AGENTS.md` | Agent instructions | `agents` |
| `HEARTBEAT.md` | Monitoring schedule | - |
| `TOOLS.md` | Tool configuration notes | `tools` |
| `PROJECTS.md` | Active projects overview | - |
| `AGENTS-REGISTRY.md` | Agent registry | - |

---

## 🚀 Active Projects

**Location:** `~/projects/`

### AI Agency
**Path:** `~/projects/ai-agency/`  
**Obsidian:** `Projects/AI Agency/`  
**Status:** Week 1 - MVP Build  

**Quick access:**
- `aiagency` - cd to project
- `aau` - Update/clean project
- `aar` - View roadmap
- `aat` - View current tasks

**Key docs:**
- EXECUTION ROADMAP.md - Complete strategy
- tasks.md - Current week actions

---

### Personal Website
**Path:** `~/projects/website/` → `~/thrmnn.github.io/`  
**Obsidian:** `Projects/Personal Website/`  
**Status:** Content ready, needs photos + deploy  

**Quick access:**
- `website` - cd to project

**Key docs:**
- README.md - Setup instructions
- PERSONAL_INFO.md - Content
- PROJECTS.md - Portfolio entries

---

### Mission Control
**Path:** `~/projects/mission-control/`  
**Status:** Deployed ✅  

**Quick access:**
- `mc` - cd to project

**URL:** https://mission-control-ruby-zeta.vercel.app

---

### Job Application Pipeline
**Path:** `~/projects/job-pipeline/`  
**Status:** Blocked (OAuth issue)  

**Quick access:**
- `cd ~/projects/job-pipeline`

---

## 📋 Common Commands

### Daily Workflow
```bash
otd              # Run /today command
omorning         # Morning routine (Obsidian)
osync            # Backup Obsidian vault
brief            # Morning brief
```

### AI Agency
```bash
aau              # Clean/update project
aar              # View roadmap
aat              # View current tasks
aiagency         # Navigate to project
```

### Navigation
```bash
cw               # Go to ~/clawd
wp               # Go to ~/projects
vault            # Go to Obsidian vault
```

### Git
```bash
gca "message"    # Add all + commit
gcp              # Push
gcap             # Add + commit + push (auto message)
gst              # Status
glog             # Pretty log
```

### Memory & Search
```bash
qms "query" [query|vsearch|search]   # Search memory
mem              # View MEMORY.md
```

---

## 📚 Documentation

**Location:** `~/clawd/docs/`

### Setup & Configuration
- `WORKFLOW-IMPROVEMENTS.md` - Organizational improvements
- `SYSTEM-V2-IMPLEMENTATION.md` - Productivity system v2
- `OBSIDIAN-SECOND-BRAIN.md` - Obsidian integration
- `PDF-WORKFLOW.md` - Working with PDFs

### Guides & Quickstarts
- `RALPH-QUICKSTART.md` - RALPH loop
- `SMART-SPAWN-QUICKSTART.md` - Spawning agents
- `TODAY-COMMAND-V2.md` - /today command docs
- `QMD-USAGE.md` - Memory search

### Troubleshooting
- `TROUBLESHOOTING.md` - Common issues
- `DOCTOR-FIXES-2026-03-14.md` - System fixes
- `obsidian-debugging.md` - Obsidian issues

### Session Summaries
- `SESSION-SUMMARY-2026-03-16.md` - Today's work
- `SESSION-UPDATE-2026-03-16-AFTERNOON.md` - Afternoon session

### Archive
- `archive/deployment-feb21/` - Old deployment guides

---

## 🤖 Automation Scripts

**Location:** `~/clawd/scripts/`

### Obsidian
- `obsidian-backup-git.sh` - Backup vault
- `obsidian-morning-routine.sh` - Daily note + sync
- `obsidian-weekly-review.sh` - Weekly review
- `obsidian.sh` - General helper
- `today-command-v2.sh` - Task extraction

### Trello
- `trello-synthesis.sh` - Task summary
- `trello-quick-actions.sh` - Quick actions
- `trello-smart-organize.sh` - Board cleanup

### Google Workspace
- `google-oauth-exchange.py` - OAuth flow
- `send-email.py` - Send email
- `send-email-with-attachment.py` - Send with PDF
- `test-gmail-access.py` - Test access

### AI Agency
- `ai-agency-update.sh` - Clean project

### Memory
- `mc-memory-search.sh` - Semantic search (QMD)
- `memory-helper.sh` - Memory utilities

### Academic Papers
- `lai-paper-workflow.sh` - LAI paper automation
- `brisa-paper-workflow.sh` - Brisa+ paper

---

## 🗂️ Memory Files

**Location:** `~/clawd/memory/`

### Daily Logs
- `YYYY-MM-DD.md` - Daily memory files
- Most recent processed daily

### State Tracking
- `heartbeat-state.json` - Heartbeat checks
- `task-progress.json` - Task tracking
- `ralph-state.json` - RALPH spawns

### X/Twitter Cache
- `x-cache/YYYY-MM-DD.json` - Daily X data

---

## 🔐 Credentials

**Location:** `~/clawd/credentials/` (gitignored)

- `trello.env` - Trello API keys
- `google-oauth-client.json` - OAuth client
- `google-tokens.json` - OAuth tokens
- `notion.env` - Notion API
- `elevenlabs.env` - TTS API

**Security:** Never commit credentials to git!

---

## 🎯 Quick Troubleshooting

### OAuth Issues
1. Check tokens: `cat ~/clawd/credentials/google-tokens.json`
2. Re-authenticate: `python3 ~/clawd/scripts/oauth-refresh-auto.py`
3. Docs: `docs/TROUBLESHOOTING.md`

### Obsidian Sync
1. Manual backup: `osync`
2. Check status: `cd ~/vault && git status`
3. Docs: `docs/OBSIDIAN-SECOND-BRAIN.md`

### Command Not Found
1. Reload aliases: `source ~/.bashrc`
2. Check script exists: `ls ~/clawd/scripts/ | grep <name>`
3. Make executable: `chmod +x ~/clawd/scripts/<name>`

---

## 📊 Directory Structure

```
~/
├── clawd/                      # Workspace root
│   ├── *.md                    # Core config (9 files)
│   ├── docs/                   # Documentation
│   ├── scripts/                # Automation
│   ├── memory/                 # Daily logs
│   └── credentials/            # API keys (gitignored)
│
├── projects/                   # All active projects
│   ├── ai-agency/              # AI agency MVP
│   ├── website/                # → ~/thrmnn.github.io
│   ├── mission-control/        # → ~/mission-control
│   └── job-pipeline/           # → ~/job-pipeline
│
├── clawd-aliases.sh            # Bash aliases
│
└── Obsidian Vault/             # (Windows path)
    └── Projects/
        ├── AI Agency/
        ├── Personal Website/
        └── Job Application Pipeline/
```

---

## 🔄 Daily Workflow

### Morning (9 AM)
1. `omorning` - Creates daily note, syncs Trello
2. `otd` - Extracts and prioritizes tasks
3. Review Obsidian dashboard

### During Day
1. Work from Trello Today list
2. Update Obsidian as you complete
3. Use `qms` to search past context

### Evening (8 PM)
1. Mark completed tasks
2. `osync` - Backup Obsidian
3. `gcap` - Auto-commit workspace

---

## 🆘 Getting Help

**Ask Zé:**
- "What's the command for X?"
- "Where is Y documented?"
- "How do I do Z?"

**Check Docs:**
- This INDEX.md (you're here!)
- WORKFLOW-IMPROVEMENTS.md
- TROUBLESHOOTING.md

**Common Patterns:**
- All aliases listed: `alias | grep -E "cw|otd|aar"`
- All scripts: `ls ~/clawd/scripts/`
- Recent work: `glog`

---

## 📈 What's Next

**This Week:**
- [ ] Build AI Agency MVP (Day 1-3)
- [ ] Implement one workflow improvement/day
- [ ] Test and refine aliases

**This Month:**
- [ ] Complete AI Agency launch
- [ ] Deploy personal website
- [ ] Fix OAuth for job pipeline

---

**Last Updated:** 2026-03-16 by Zé 😌  
**Source:** `~/clawd/docs/INDEX.md`
