# Obsidian Sync - Cron Setup Commands

## Quick Install

Copy and paste these commands into your terminal:

```bash
# Open crontab editor
crontab -e

# Add these two lines (paste at the end of the file):
0 9 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
0 20 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1

# Save and exit (:wq in vim, Ctrl+O then Ctrl+X in nano)
```

## What This Does

### Morning Sync (9 AM)
```bash
0 9 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```
- Runs at 9:00 AM every day
- Pulls latest from Obsidian → workspace
- Logs output to `~/clawd/logs/obsidian-sync-cron.log`

### Evening Sync (8 PM)
```bash
0 20 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```
- Runs at 8:00 PM every day
- Pushes workspace updates → Obsidian
- Logs output to `~/clawd/logs/obsidian-sync-cron.log`

## Cron Time Format

```
 ┌───────────── minute (0 - 59)
 │ ┌───────────── hour (0 - 23)
 │ │ ┌───────────── day of month (1 - 31)
 │ │ │ ┌───────────── month (1 - 12)
 │ │ │ │ ┌───────────── day of week (0 - 6) (Sunday=0)
 │ │ │ │ │
 │ │ │ │ │
 * * * * * command to execute
```

## Custom Schedules (Examples)

### More Frequent Syncs
```bash
# Every 2 hours (pull)
0 */2 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1

# Every 4 hours (push)
0 */4 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```

### Weekdays Only
```bash
# 9 AM on weekdays (Monday-Friday)
0 9 * * 1-5 /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1

# 8 PM on weekdays
0 20 * * 1-5 /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```

### Mid-day Sync
```bash
# Add a midday pull at 1 PM
0 13 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```

## Verification Commands

### Check Cron Jobs
```bash
# List current cron jobs
crontab -l

# Expected output:
# 0 9 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
# 0 20 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
```

### Check Cron Service Status
```bash
# Check if cron daemon is running
systemctl status cron

# Start cron if stopped
sudo systemctl start cron

# Enable cron on boot
sudo systemctl enable cron
```

### View Cron Logs
```bash
# View sync execution log
tail -30 ~/clawd/logs/obsidian-sync-cron.log

# Watch live
tail -f ~/clawd/logs/obsidian-sync-cron.log

# Check system cron log
grep CRON /var/log/syslog | tail -20
```

## Troubleshooting

### Cron Not Running

**Issue:** Jobs not executing at scheduled time

**Solutions:**
```bash
# 1. Check cron service
systemctl status cron

# 2. Check system time
date

# 3. Verify crontab syntax
crontab -l

# 4. Check cron logs
grep CRON /var/log/syslog | tail -20
```

### Permission Errors

**Issue:** Script can't access Obsidian or workspace

**Solutions:**
```bash
# 1. Verify script is executable
ls -l ~/clawd/scripts/obsidian-workspace-sync.sh
# Should show: -rwxr-xr-x

# 2. Make executable if needed
chmod +x ~/clawd/scripts/obsidian-workspace-sync.sh

# 3. Test manually
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull
```

### Path Not Found

**Issue:** Cron can't find script or files

**Solutions:**
```bash
# Use ABSOLUTE paths in crontab (already done)
# ✓ Good: /home/theo/clawd/scripts/obsidian-workspace-sync.sh
# ✗ Bad: ~/clawd/scripts/obsidian-workspace-sync.sh

# Current cron uses absolute paths, so this shouldn't be an issue
```

### No Output in Logs

**Issue:** Cron log file is empty

**Solutions:**
```bash
# 1. Check if log directory exists
ls -la ~/clawd/logs/

# 2. Create if needed
mkdir -p ~/clawd/logs/

# 3. Check file permissions
touch ~/clawd/logs/obsidian-sync-cron.log
chmod 644 ~/clawd/logs/obsidian-sync-cron.log

# 4. Wait for next scheduled run or test manually
/home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> ~/clawd/logs/obsidian-sync-cron.log 2>&1
```

## Removing Cron Jobs

If you need to disable automatic sync:

```bash
# Edit crontab
crontab -e

# Delete or comment out (add # at start) the sync lines:
# 0 9 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh pull >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1
# 0 20 * * * /home/theo/clawd/scripts/obsidian-workspace-sync.sh push >> /home/theo/clawd/logs/obsidian-sync-cron.log 2>&1

# Save and exit
```

## Testing Before Production

Test manually before adding to cron:

```bash
# 1. Test pull
bash ~/clawd/scripts/obsidian-workspace-sync.sh pull

# 2. Test push
bash ~/clawd/scripts/obsidian-workspace-sync.sh push

# 3. Check logs
cat ~/clawd/logs/obsidian-sync.log

# 4. Verify files synced
ls -la ~/projects/ai-agency/docs/
```

Once manual tests work, add to cron with confidence.

---

**Ready to Install?** Run:
```bash
crontab -e
```

Then paste the two cron lines at the end of the file. 🚀
