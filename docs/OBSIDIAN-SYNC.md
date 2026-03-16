# Obsidian ↔ Workspace Sync

Bidirectional sync automation between Obsidian vault and workspace for the AI Agency project.

## Overview

**Purpose:** Keep AI Agency documentation synchronized between Obsidian (source of truth) and workspace (where Zé works).

**Paths:**
- **Obsidian:** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault/Projects/AI Agency/`
- **Workspace:** `~/projects/ai-agency/docs/`

**Strategy:** Two-way sync with timestamp-based conflict avoidance (newer files win).

---

## Quick Start

```bash
# Pull latest from Obsidian (morning)
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull

# Push updates to Obsidian (evening)
bash ~/clawd/scripts/obsidian-workspace-sync.sh push
```

---

## How It Works

### Pull Mode (Obsidian → workspace)
**When:** Morning (9 AM) - Start day with latest from Obsidian  
**What:** Copies newer files from Obsidian to workspace  
**Use case:** You edited notes in Obsidian overnight; Zé needs latest versions

```bash
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull
```

### Push Mode (workspace → Obsidian)
**When:** Evening (8 PM) - End day by saving work to Obsidian  
**What:** Copies newer files from workspace to Obsidian  
**Use case:** Zé created/updated docs during the day; save to Obsidian vault

```bash
bash ~/clawd/scripts/obsidian-workspace-sync.sh push
```

### Conflict Resolution
- **Newer file wins** (based on modification timestamp)
- No automatic deletion (safe mode)
- Preview shown before sync
- All operations logged

---

## Features

### Safe Sync
- `rsync --update`: Only copy if source is newer than destination
- No `--delete`: Files never removed automatically
- Excluded folders: `.obsidian/`, `.trash/`, `.git/`
- Excluded files: `*.tmp`, `.DS_Store`

### Logging
All sync operations logged to: `~/clawd/logs/obsidian-sync.log`

```bash
# View recent sync history
tail -20 ~/clawd/logs/obsidian-sync.log

# Watch live sync
tail -f ~/clawd/logs/obsidian-sync.log
```

### Preview Mode
Script shows what will be synced before executing (dry-run preview).

---

## Cron Automation

### Setup Commands

Add these to your crontab (`crontab -e`):

```bash
# Morning pull: Get latest from Obsidian at 9 AM
0 9 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1

# Evening push: Save work to Obsidian at 8 PM
0 20 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```

### Manual Installation

```bash
# Edit crontab
crontab -e

# Add the two lines above, then save and exit
```

### Verify Cron Setup

```bash
# List current cron jobs
crontab -l

# Check cron logs
tail ~/clawd/logs/obsidian-sync-cron.log
```

---

## Common Workflows

### Daily Routine

**Morning (9 AM - automatic):**
1. Cron pulls latest from Obsidian → workspace
2. Zé has fresh context for the day

**During the day:**
3. Zé creates/updates docs in `~/projects/ai-agency/docs/`
4. You might edit in Obsidian too (conflicts handled by timestamp)

**Evening (8 PM - automatic):**
5. Cron pushes workspace updates → Obsidian
6. Everything backed up to OneDrive via Obsidian vault

### Manual Sync (Anytime)

```bash
# Just finished editing in Obsidian, need it in workspace now
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull

# Zé just created important doc, want it in Obsidian immediately
bash ~/clawd/scripts/obsidian-workspace-sync.sh push
```

### Debugging

```bash
# Check if paths are accessible
ls -la "/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault/Projects/AI Agency/"
ls -la ~/projects/ai-agency/docs/

# Test sync manually
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull

# Check logs
tail -30 ~/clawd/logs/obsidian-sync.log
```

---

## File Flow Diagram

```
Morning (9 AM):
┌─────────────┐           ┌──────────────┐
│  Obsidian   │  ──pull──>│  Workspace   │
│  (source)   │           │  (Zé works)  │
└─────────────┘           └──────────────┘

Evening (8 PM):
┌─────────────┐           ┌──────────────┐
│  Obsidian   │  <──push──│  Workspace   │
│  (backup)   │           │  (updates)   │
└─────────────┘           └──────────────┘
```

---

## Safety Notes

### What WON'T Happen
- ✅ Files won't be deleted (no `--delete` flag)
- ✅ Older files won't overwrite newer ones (`--update` flag)
- ✅ Hidden Obsidian config won't be touched (`.obsidian/` excluded)
- ✅ Git repos won't be corrupted (`.git/` excluded)

### What WILL Happen
- ✅ Newer files copy over older ones (expected behavior)
- ✅ New files appear in destination (expected behavior)
- ✅ All operations logged with timestamps

### Edge Cases
- **Simultaneous edits:** If you edit the same file in both places between syncs, the last-modified timestamp determines which version wins
- **Large files:** Sync may take longer, check logs for progress
- **Network issues:** If OneDrive is syncing and file is locked, rsync will skip it and log warning

---

## Troubleshooting

### "Obsidian path not found"
```bash
# Check if WSL can access Windows filesystem
ls /mnt/c/Users/theoh/OneDrive/Documents/

# Verify OneDrive is syncing
# (Check Windows OneDrive status icon)
```

### "Permission denied"
```bash
# Make script executable
chmod +x ~/clawd/scripts/obsidian-workspace-sync.sh
```

### "Sync not running automatically"
```bash
# Check if cron is running
systemctl status cron

# Verify cron entries
crontab -l

# Check cron logs
grep CRON /var/log/syslog | tail -20
```

### "Files not syncing"
```bash
# Run manual sync with verbose output
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull

# Check what would be synced (dry-run)
rsync -avh --update --dry-run \
  "/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault/Projects/AI Agency/" \
  ~/projects/ai-agency/docs/
```

---

## Integration with Obsidian System

This sync complements the existing Obsidian setup:

- **Obsidian vault:** Source of truth (backed up to OneDrive + Git)
- **Workspace:** Working directory for Zé
- **Trello sync:** Still works independently (uses Obsidian path directly)
- **Git backup:** Backs up entire vault including AI Agency folder

No conflicts — each system has its purpose:
- **This sync:** AI Agency docs ↔ workspace
- **Trello sync:** Tasks → daily notes
- **Git backup:** Entire vault → Git repo

---

## Files Created

```
~/clawd/scripts/obsidian-workspace-sync.sh     # Main sync script
~/clawd/docs/OBSIDIAN-SYNC.md                  # This documentation
~/clawd/logs/obsidian-sync.log                 # Sync operation log
~/clawd/logs/obsidian-sync-cron.log            # Cron execution log
~/projects/ai-agency/docs/                     # Workspace destination (auto-created)
```

---

## Future Enhancements (Optional)

- [ ] Add `--force` flag to ignore timestamps and copy anyway
- [ ] Add `--dry-run` flag for testing without changes
- [ ] Email/notification on sync failure
- [ ] Sync statistics (files copied, size, duration)
- [ ] Support for multiple project folders
- [ ] Interactive conflict resolution mode

---

**Status:** ✅ Production Ready  
**Created:** 2026-03-16  
**Last Updated:** 2026-03-16
