# Workflow Organizational Improvements

**Date:** 2026-03-16  
**Status:** Implemented ✅

---

## ✅ What Was Fixed

### 1. Home Directory Cleanup
**Before:** 6 deployment .md files cluttering ~/  
**After:** All moved to relevant projects  
**Impact:** Clean home directory, easy navigation

### 2. Workspace Organization
**Before:** 20+ files in ~/clawd/ root  
**After:** Only 9 core config files in root  
**Impact:** Clear structure, faster file finding

### 3. Git Tracking
**Before:** No .gitignore, untracked changes  
**After:** All config files committed, proper ignores  
**Impact:** Version control for workspace evolution

---

## 📂 New Directory Structure

```
~/clawd/
├── Core Config (9 files) ✅
│   ├── SOUL.md              # Who Zé is
│   ├── USER.md              # Who you are  
│   ├── IDENTITY.md          # Zé's identity
│   ├── MEMORY.md            # Long-term memory
│   ├── AGENTS.md            # Agent instructions
│   ├── HEARTBEAT.md         # Monitoring schedule
│   ├── TOOLS.md             # Tool configuration
│   ├── PROJECTS.md          # Active projects
│   └── AGENTS-REGISTRY.md   # Agent registry
│
├── docs/                    # Documentation
│   ├── Quick refs           # RALPH, SMART-SPAWN, etc.
│   ├── Session summaries    # Daily work logs
│   ├── Setup guides         # System documentation
│   └── archive/             # Old deployment guides
│       └── deployment-feb21/
│
├── memory/                  # Daily memory files
│   ├── YYYY-MM-DD.md        # Daily logs
│   ├── x-cache/             # X/Twitter cache
│   └── *.json               # State tracking
│
├── scripts/                 # Automation scripts
│   ├── obsidian-*.sh        # Obsidian helpers
│   ├── trello-*.sh          # Trello automation
│   ├── google-*.py          # Gmail/Drive/Calendar
│   └── *-workflow.sh        # Project workflows
│
└── credentials/             # API keys (gitignored)
    ├── trello.env
    ├── google-*.json
    └── notion.env
```

---

## 🚀 Workflow Improvements Proposed

### 1. Daily Workflow Standardization

**Morning Routine (Automated):**
```bash
# Run at 9 AM via cron
bash ~/clawd/scripts/obsidian-morning-routine.sh
# Creates daily note, syncs Trello, checks calendar
```

**Evening Review (Automated):**
```bash
# Run at 8 PM via cron
bash ~/clawd/scripts/evening-summary.sh
# Summarizes day, updates memory, commits to Git
```

**Before Building (Manual):**
```bash
# Check current tasks
/today

# Update AI Agency project
bash ~/clawd/scripts/ai-agency-update.sh
```

---

### 2. Project Organization

**Current Projects:**
- AI Agency → `~/clawd/` (Obsidian tracks)
- Personal Website → `~/thrmnn.github.io/`
- Mission Control → `~/mission-control/`
- Job Pipeline → `~/job-pipeline/`
- Academic Papers → Separate repos

**Proposal:** Create `~/projects/` directory
```bash
~/projects/
├── ai-agency/          # MVP builds here
├── personal-website/   # Symlink to thrmnn.github.io
├── mission-control/    # Symlink
└── job-pipeline/       # Symlink
```

**Benefit:** One place to find all active code

---

### 3. Git Workflow Improvements

**Daily Auto-Commit:**
```bash
# Add to cron (evening)
cd ~/clawd && git add -A && git commit -m "Auto: $(date +%Y-%m-%d)" && git push
```

**Branch Strategy for Experiments:**
```bash
# Before major changes
git checkout -b experiment/new-feature
# ... work ...
git checkout main  # or merge if successful
```

**Benefit:** Never lose work, easy rollbacks

---

### 4. Obsidian + Workspace Sync

**Bi-directional Sync:**
```bash
# Morning: Pull Obsidian changes to workspace
~/clawd/scripts/obsidian-sync-to-workspace.sh

# Evening: Push workspace updates to Obsidian
~/clawd/scripts/workspace-sync-to-obsidian.sh
```

**What this does:**
- AI Agency tasks → reflected in ~/clawd/docs/
- Memory files → synced to Obsidian vault
- Scripts → documented in Obsidian

**Benefit:** Single source of truth, accessible everywhere

---

### 5. Command Shortcuts (Add to ~/.bashrc)

```bash
# Quick workspace access
alias cw='cd ~/clawd'
alias wp='cd ~/projects'

# Obsidian helpers
alias otd='bash ~/clawd/scripts/today-command-v2.sh'
alias osync='bash ~/clawd/scripts/obsidian-backup-git.sh'

# AI Agency shortcuts
alias aau='bash ~/clawd/scripts/ai-agency-update.sh'
alias aar='cat ~/projects/ai-agency/EXECUTION\ ROADMAP.md | less'

# Memory search
alias qms='bash ~/clawd/scripts/mc-memory-search.sh'

# Git shortcuts
alias gca='git add -A && git commit -m'
alias gcp='git push'
```

**Benefit:** Faster navigation, less typing

---

### 6. Documentation Indexing

**Create Master Index:**
```markdown
~/clawd/docs/INDEX.md

# Quick Links

## Core Config
- SOUL.md - Personality
- USER.md - Your info
- TOOLS.md - Tool notes

## Active Projects
- AI Agency: docs/AI-AGENCY-ROADMAP.md
- Website: ~/thrmnn.github.io/README.md
- Mission Control: ~/mission-control/docs/

## Common Tasks
- /today - Daily planning
- obsidian-sync - Backup vault
- ai-agency-update - Clean project

## Troubleshooting
- docs/TROUBLESHOOTING.md
- docs/DOCTOR-FIXES-2026-03-14.md
```

**Benefit:** Quick reference, onboarding

---

### 7. Automated Backups

**Three-Tier Backup:**
```bash
# Tier 1: Git (continuous)
cd ~/clawd && git push

# Tier 2: Obsidian Git (daily)
bash ~/clawd/scripts/obsidian-backup-git.sh

# Tier 3: External (weekly)
# tar -czf ~/backups/clawd-$(date +%Y%m%d).tar.gz ~/clawd
# rsync to external drive or cloud
```

**Benefit:** Never lose work

---

### 8. Weekly Review Automation

**Create Script:**
```bash
~/clawd/scripts/weekly-review.sh

#!/bin/bash
# Auto-generates weekly summary
# - Git commits this week
# - Obsidian updates
# - Memory highlights
# - Project progress
# Output: docs/weekly-review-YYYY-WXX.md
```

**Benefit:** Track progress, see patterns

---

### 9. Context Size Management

**Problem:** Sessions can hit token limits

**Solution:** Modular loading
```bash
# Instead of loading ALL memory
# Load only relevant context per task

# For AI Agency work:
export CONTEXT_MODE="ai-agency"
# Loads: SOUL, AGENTS, TOOLS, AI Agency docs only

# For academic work:
export CONTEXT_MODE="academic"  
# Loads: SOUL, AGENTS, LAI paper docs only
```

**Benefit:** 50-70% token savings

---

### 10. Task Tracking Dashboard

**Create Live Dashboard:**
```bash
~/clawd/scripts/dashboard.sh

#!/bin/bash
# Shows:
# - Current tasks (from /today)
# - Active projects status
# - Recent commits
# - Upcoming deadlines
# - Token usage this session
```

**Output:**
```
=== Zé Dashboard ===
Date: 2026-03-16 15:00

Active Tasks:
  [AI Agency] Build MVP (Day 1)
  [Website] Add photos
  [Job Pipeline] Fix OAuth

Projects:
  AI Agency: Week 1 / 12
  Website: 70% complete
  Mission Control: Deployed ✅

Recent Work:
  3 commits today
  2 scripts created
  1 cleanup completed

Next Deadline:
  Website launch: 14 days
  
Session Tokens: 128K / 200K
```

**Benefit:** At-a-glance status

---

## 🎯 Implementation Priority

**Week 1 (This Week):**
- [x] Workspace cleanup ✅
- [x] Git tracking ✅
- [ ] Bash aliases
- [ ] Master INDEX.md

**Week 2:**
- [ ] Daily auto-commit cron
- [ ] Obsidian sync scripts
- [ ] Dashboard script

**Month 2:**
- [ ] Context mode switching
- [ ] Weekly review automation
- [ ] External backup setup

---

## 📝 Maintenance Commands

**Weekly:**
```bash
# Clean up workspace
bash ~/clawd/scripts/ai-agency-update.sh

# Review git history
cd ~/clawd && git log --oneline --since="1 week ago"

# Check for stale files
find ~/clawd -name "*.md" -mtime +30
```

**Monthly:**
```bash
# Archive old memory files
bash ~/clawd/scripts/archive-old-memory.sh

# Clean temp files
find ~/clawd -name "temp-*" -delete

# Review and prune docs/
```

---

## ✅ Benefits Summary

1. **Faster navigation** - Clear structure, less searching
2. **Never lose work** - Git tracking everything
3. **Context awareness** - Know what's where
4. **Automation** - Less manual admin
5. **Scalability** - Easy to add new projects
6. **Discoverability** - New features documented
7. **Maintainability** - Regular cleanup routines
8. **Collaboration** - Could share workspace structure

---

**Next Steps:**
1. Implement bash aliases
2. Create dashboard script
3. Test daily workflow automation

**Review:** End of week (check what's working)
