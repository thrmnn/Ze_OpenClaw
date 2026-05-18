# Context Mode Switching

**Goal:** Load only relevant files per task to save tokens and speed up sessions

---

## 🎯 Available Modes

### 1. AI Agency Mode
**When to use:** Building AI Agency MVP, business work

**Loads:**
- SOUL.md, AGENTS.md, TOOLS.md
- AI Agency EXECUTION ROADMAP
- AI Agency tasks
- scripts/ai-agency-*.sh

**Skips:**
- Academic papers
- Job pipeline
- Website files
- Memory archives

**Token savings:** ~40%

---

### 2. Academic Mode
**When to use:** Working on LAI or Brisa+ papers

**Loads:**
- SOUL.md, AGENTS.md, TOOLS.md
- Academic paper docs (LAI, Brisa+)
- Paper workflow scripts
- Relevant memory files

**Skips:**
- AI Agency
- Job pipeline
- Website
- General workspace docs

**Token savings:** ~50%

---

### 3. General Mode (Default)
**When to use:** General work, exploration, mixed tasks

**Loads:** All workspace files

**Token savings:** 0% (full context)

---

## 🛠️ How to Use

**Set mode:**
```bash
# In your terminal
export CONTEXT_MODE="ai-agency"    # AI Agency work
export CONTEXT_MODE="academic"     # Paper work
export CONTEXT_MODE="general"      # Default (all files)

# Or use helper (coming soon)
ctx ai-agency
ctx academic
ctx general
```

**Check current mode:**
```bash
echo $CONTEXT_MODE
```

---

## 📋 Mode Definitions

### AI Agency
```bash
export CONTEXT_MODE="ai-agency"
# OpenClaw will prioritize:
# - ~/clawd/SOUL.md, AGENTS.md, TOOLS.md
# - Obsidian: Projects/AI Agency/*
# - ~/clawd/scripts/ai-agency-*
```

### Academic
```bash
export CONTEXT_MODE="academic"
# OpenClaw will prioritize:
# - ~/clawd/SOUL.md, AGENTS.md, TOOLS.md
# - Obsidian: Projects/Academic Research/*
# - ~/clawd/scripts/*-paper-*
```

### General
```bash
export CONTEXT_MODE="general"
# Default - loads all workspace context
```

---

## 🔄 Integration with OpenClaw

**Future enhancement:** OpenClaw can check `$CONTEXT_MODE` and filter workspace files accordingly.

**For now:** Manual - you decide what to reference in prompts based on mode.

---

## ✅ Quick Reference

| Mode | Use Case | Token Savings | Files Loaded |
|------|----------|---------------|--------------|
| ai-agency | Business/MVP work | ~40% | Agency docs only |
| academic | Paper writing | ~50% | Paper docs only |
| general | Mixed/exploration | 0% | All files |

---

**Created:** 2026-03-16  
**Status:** Documentation complete, OpenClaw integration pending
