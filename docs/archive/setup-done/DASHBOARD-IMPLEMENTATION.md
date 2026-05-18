# Dashboard Script - Implementation Plan

**Goal:** At-a-glance workspace status in terminal  
**Time:** 20 minutes to implement  
**Impact:** Know what's happening without searching

---

## 🎯 Purpose

**Problem:** 
- Don't know current status without checking multiple files
- Hard to see progress at a glance
- Token usage is invisible until you hit limits

**Solution:**
A single command that shows:
- Current tasks (from /today)
- Active projects status
- Recent work (git commits)
- Upcoming deadlines
- Token usage this session
- System health

---

## 📊 Dashboard Sections

### 1. Header (Always)
```
=== Zé Dashboard ===
Date: 2026-03-16 17:05
Location: ~/clawd
```

### 2. Current Focus (from /today)
```
🎯 Today's Focus:
  [AI Agency] Build MVP - Day 1
  [Website] Add project photos
  [Job Pipeline] Fix OAuth (blocked)
```

### 3. Active Projects
```
📂 Active Projects:
  AI Agency       Week 1/12  🔴 Planning
  Personal Website  70% done   🟢 Content ready
  Mission Control   Deployed   ✅ Complete
  Job Pipeline      Blocked    🔴 OAuth issue
```

### 4. Recent Activity (Git)
```
📝 Recent Work (last 5 commits):
  d58734e - Add aliases, master index (2 hours ago)
  1f06e60 - Workspace cleanup (3 hours ago)
  a1468c1 - Add AI Agency command (3 hours ago)
```

### 5. Upcoming Deadlines
```
⏰ Upcoming Deadlines:
  Personal Website  14 days  (End of March)
  LAI Paper         14 days  (March 2026)
  Brisa+ Paper      105 days (June 2026)
```

### 6. Token Usage (if available)
```
🎫 Session Tokens:
  Used: 137K / 200K (68.5%)
  Remaining: 63K
```

### 7. Quick Actions
```
💡 Quick Actions:
  otd     - Run /today
  aar     - View AI Agency roadmap
  glog    - Recent commits
  osync   - Backup Obsidian
```

---

## 🛠️ Implementation

### Data Sources

**1. Current tasks** → Parse `/today` command output  
**2. Projects** → Read from PROJECTS.md or Obsidian  
**3. Git commits** → `git log --oneline -5`  
**4. Deadlines** → Hardcoded or from project.md files  
**5. Tokens** → Parse from session env or usage tracking

### Script Structure

```bash
#!/bin/bash
# ~/clawd/scripts/dashboard.sh

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Header
show_header() { ... }

# Current focus
show_focus() {
  # Parse today's tasks from Obsidian or last /today output
}

# Active projects
show_projects() {
  # Read from PROJECTS.md or Obsidian Projects/
}

# Recent commits
show_git() {
  cd ~/clawd
  git log --oneline --graph --decorate -5
}

# Deadlines
show_deadlines() {
  # Hardcoded or parsed from project files
}

# Token usage (if available)
show_tokens() {
  # Check if in OpenClaw session
  # Parse OPENCLAW_SESSION_USAGE or similar
}

# Quick actions
show_actions() {
  # Just print helpful aliases
}

# Main
main() {
  show_header
  show_focus
  show_projects
  show_git
  show_deadlines
  show_tokens
  show_actions
}

main
```

---

## 🎨 Visual Design

**Use colors:**
- 🟢 Green - Complete/Active
- 🟡 Yellow - In Progress
- 🔴 Red - Blocked/Critical
- 🔵 Blue - Information

**Use emojis:**
- 🎯 Focus/Goals
- 📂 Projects
- 📝 Activity
- ⏰ Deadlines
- 🎫 Tokens
- 💡 Actions

**Keep it compact:**
- Max 30 lines total
- One screen, no scrolling
- Quick scan <5 seconds

---

## 📋 Implementation Steps

**1. Create basic script (5 min)**
- Header + structure
- Placeholder sections

**2. Implement git section (2 min)**
- Easy win, just `git log`

**3. Add project status (5 min)**
- Parse PROJECTS.md or hardcode initial

**4. Add current focus (3 min)**
- Parse last /today output or Obsidian daily note

**5. Add deadlines (3 min)**
- Hardcode known deadlines

**6. Polish output (2 min)**
- Colors, spacing, emojis

**Total: 20 minutes**

---

## 🧪 Testing

```bash
# Run dashboard
bash ~/clawd/scripts/dashboard.sh

# Or use alias
dash

# Should show clean, readable output
# All sections populated
# No errors
```

---

## 🔄 Future Enhancements

**Phase 2 (later):**
- Auto-refresh (watch mode)
- Integrate with Mission Control
- Show AI agent status
- Calendar events today
- Weather
- Motivational quote

**Keep it simple for now!**

---

## ✅ Success Criteria

Dashboard is done when:
- [x] Script exists and runs
- [x] All 7 sections show data
- [x] Output is clean and readable
- [x] Takes <5 seconds to run
- [x] Alias `dash` works
- [x] Committed to git

---

**Ready to implement?** Let's build it now!
