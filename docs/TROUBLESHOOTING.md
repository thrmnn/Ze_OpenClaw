# Troubleshooting Guide

Common issues and solutions for Clawdbot operations.

---

## Gmail / Google Workspace Issues

### "Can't send email" or "SMTP not configured"

**Problem:** Trying to use SMTP instead of Google Workspace API

**Solution:**
```bash
# Use the Google Workspace API (already configured!)
cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email.py --to recipient@example.com --subject "Test" --body "Body"
```

**Why it works:**
- Google Workspace OAuth is configured in `credentials/google-tokens.json`
- Must activate `venv-google` virtualenv first
- Use Gmail API, not SMTP

**Verify access:**
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/test-gmail-access.py
```

---

## Claude Code CLI Not Responding

**Problem:** `claude -p "prompt"` hangs or times out

**Symptoms:**
- Job pipeline LLM integration fails
- Commands like `claude -p "test"` never return
- Timeout errors in pipeline logs

**Workarounds:**
1. **Use Clawdbot's native LLM** - Manually optimize instead of relying on Claude Code CLI
2. **Debug authentication:**
   ```bash
   claude --version  # Should return version number
   claude -p "test"  # Should respond quickly
   ```
3. **Check session:** May need to re-authenticate or restart Claude Code

**Long-term fix:** Consider switching to direct API calls instead of CLI dependency

---

## Memory/Context Issues

### "I don't remember that"

**Solution:** Check memory files
```bash
# Search for topic
grep -r "topic" ~/clawd/memory/

# Read recent memory
cat ~/clawd/memory/$(date +%Y-%m-%d).md
cat ~/clawd/MEMORY.md
```

**Tip:** Use `memory_search` tool when available

---

## Heartbeat Not Working

**Problem:** Heartbeat checks not running or always returning HEARTBEAT_OK

**Check:**
1. Does `HEARTBEAT.md` exist?
   ```bash
   cat ~/clawd/HEARTBEAT.md
   ```

2. Is `heartbeat-state.json` being updated?
   ```bash
   cat ~/clawd/memory/heartbeat-state.json
   ```

3. Are System messages (cron events) being processed?
   - Look for `System: [timestamp] ...` messages
   - These must be processed BEFORE checking HEARTBEAT.md

---

## Job Pipeline Issues

### Pipeline freezes or times out

**Common causes:**
1. LLM calls timing out (Claude Code CLI issue)
2. Missing dependencies
3. Python version incompatibility (needs Python 3.8+)

**Solutions:**
```bash
# Check Python version
python3 --version

# Test pipeline without LLM
cd ~/clawd/job-pipeline
python3 main.py test

# Check logs for errors
cd ~/clawd/job-pipeline
tail -f pipeline.log  # if logging is enabled
```

---

## MCP Server Issues

### "MCP not responding"

**Trello MCP:**
```bash
# Check credentials
cat ~/clawd/credentials/trello.env

# Test MCP wrapper
bash ~/clawd/credentials/trello-mcp.sh
```

**Google Workspace MCP:**
```bash
# Verify tokens
cat ~/clawd/credentials/google-tokens.json

# Test access
cd ~/clawd && source venv-google/bin/activate
python3 scripts/test-gmail-access.py
```

---

## Common Error Messages

### "No module named 'X'"

**Solution:** Wrong Python environment
```bash
# Check which env you need:
# - Google API: venv-google
# - Whisper: venv-whisper
# - Job pipeline: system Python

cd ~/clawd && source venv-google/bin/activate  # or venv-whisper
```

### "ENOENT: no such file or directory"

**Solution:** File path issue - check if path is relative or absolute
```bash
# Use absolute paths or cd to workspace first
cd ~/clawd
python3 scripts/script.py

# Or use absolute path
python3 ~/clawd/scripts/script.py
```

### "Permission denied"

**Solution:** Script not executable
```bash
chmod +x ~/clawd/scripts/script.py
```

---

## When All Else Fails

1. **Check logs:**
   ```bash
   clawdbot logs
   clawdbot gateway status
   ```

2. **Restart gateway:**
   ```bash
   clawdbot gateway restart
   ```

3. **Check workspace context files:**
   ```bash
   ls -lh ~/clawd/*.md
   cat ~/clawd/AGENTS.md
   cat ~/clawd/TOOLS.md
   ```

4. **Update memory:**
   ```bash
   # Document the issue in today's memory file
   echo "## Issue: [description]" >> ~/clawd/memory/$(date +%Y-%m-%d).md
   ```

---

**Last Updated:** 2026-01-30  
**Maintained by:** Zé (Clawdbot Agent)
