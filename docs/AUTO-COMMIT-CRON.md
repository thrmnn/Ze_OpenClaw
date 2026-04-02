# Auto-Commit Cron Job

## Purpose
Automatically commit and push changes in the ~/clawd workspace every day at 8 PM (20:00).

## Configuration

### Cron Schedule
```
0 20 * * * cd ~/clawd && git add -A && git commit -m "Auto: $(date +\%Y-\%m-\%d)" && git push >> ~/clawd/logs/auto-commit.log 2>&1
```

**Breakdown:**
- `0 20 * * *` - Runs at 20:00 (8 PM) every day
- `cd ~/clawd` - Navigate to workspace
- `git add -A` - Stage all changes (new, modified, deleted files)
- `git commit -m "Auto: $(date +\%Y-\%m-\%d)"` - Commit with date-stamped message
- `git push` - Push to remote repository
- `>> ~/clawd/logs/auto-commit.log 2>&1` - Log output (append mode, includes errors)

### Installation

**Add to crontab:**
```bash
(crontab -l 2>/dev/null; echo '0 20 * * * cd ~/clawd && git add -A && git commit -m "Auto: $(date +\%Y-\%m-\%d)" && git push >> ~/clawd/logs/auto-commit.log 2>&1') | crontab -
```

**Verify installation:**
```bash
crontab -l | grep auto-commit
```

**Remove (if needed):**
```bash
crontab -l | grep -v "cd ~/clawd && git add" | crontab -
```

### Log File
- **Location:** `~/clawd/logs/auto-commit.log`
- **Format:** Appends each run's output
- **Check logs:** `tail -f ~/clawd/logs/auto-commit.log`

### Manual Test
Run the command manually to test:
```bash
cd ~/clawd && git add -A && git commit -m "Auto: $(date +%Y-%m-%d)" && git push >> ~/clawd/logs/auto-commit.log 2>&1
```

## Notes

### WSL Considerations
Since you're running on WSL (Windows Subsystem for Linux), cron may not start automatically on boot.

**Start cron service manually:**
```bash
sudo service cron start
# or
sudo /etc/init.d/cron start
```

**Check if cron is running:**
```bash
ps aux | grep cron
```

**Auto-start cron on WSL login (optional):**
Add to `~/.bashrc` or `~/.profile`:
```bash
# Auto-start cron if not running
if ! pgrep -x "cron" > /dev/null; then
    sudo service cron start 2>/dev/null
fi
```

**Alternative: Windows Task Scheduler**
For more reliable scheduling on WSL, consider using Windows Task Scheduler to run:
```
wsl bash -c "cd ~/clawd && git add -A && git commit -m 'Auto: $(date +%Y-%m-%d)' && git push >> ~/clawd/logs/auto-commit.log 2>&1"
```

### Commit Behavior
- If no changes exist, `git commit` will fail gracefully (exit code 1) with message "nothing to commit"
- This is expected behavior and won't break the cron job
- Logs will show "nothing to commit, working tree clean"

### Git Authentication
- Ensure SSH keys are configured for push access
- Or use credential helper for HTTPS
- Test manually first: `cd ~/clawd && git push`

### Timezone
- Cron uses system timezone
- Current system timezone: America/Sao_Paulo (GMT-3)
- 20:00 = 8 PM local time

## Maintenance

**View recent activity:**
```bash
tail -20 ~/clawd/logs/auto-commit.log
```

**Check cron status:**
```bash
systemctl status cron  # Debian/Ubuntu
# or
service cron status
```

**Temporary disable:**
```bash
# Comment out the line in crontab
crontab -e
# Add # at start of the auto-commit line
```

---

**Created:** 2026-03-16  
**Status:** Active  
**Last Updated:** 2026-03-16
