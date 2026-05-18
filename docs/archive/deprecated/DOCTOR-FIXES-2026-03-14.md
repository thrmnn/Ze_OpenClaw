# OpenClaw Doctor Fixes - 2026-03-14

## Issues Fixed ✅

### 1. Memory Search Warnings
**Problem:** OpenClaw's built-in memory search was enabled but no embedding provider (OpenAI/Google/Voyage/Mistral) was configured.

**Solution:** Disabled built-in memory search since you're using QMD (Quick Markdown Search) instead.

**Config Change:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "enabled": false
      }
    }
  }
}
```

**Result:** No more embedding provider warnings in `openclaw doctor`.

---

### 2. Telegram Group Policy
**Problem:** Group policy was set to "allowlist" but no IDs were configured, causing all group messages to be silently dropped.

**Solution:** Changed policy to "open" to accept group messages.

**Config Change:**
```json
{
  "channels": {
    "telegram": {
      "groupPolicy": "open"
    }
  }
}
```

**Result:** Telegram can now receive group messages.

---

### 3. Obsidian Vault Setup
**Problem:** Obsidian skill was listed but not configured for your WSL environment.

**Solution:** Created custom helper script for direct file operations (no API needed).

**Details:**
- Vault: `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault`
- Helper: `~/clawd/scripts/obsidian.sh`
- Operations: search, search-content, list, create, read, append

**Quick Test:**
```bash
bash ~/clawd/scripts/obsidian.sh list
bash ~/clawd/scripts/obsidian.sh read "Welcome"
```

---

## Issues Remaining (Manual Intervention Required)

### Node Runtime Warning ⚠️

**Problem:** OpenClaw is using Node from NVM (`/home/theo/.nvm/versions/node/v24.12.0/bin/node`) instead of a system-installed version. This can break after NVM upgrades.

**Impact:** Low priority - current setup works fine, but could break if you update/remove NVM.

**Recommended Fix:**
Install Node 24 LTS via system package manager (requires sudo):

```bash
# 1. Add NodeSource repository (Node 24 LTS)
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

# 2. Install Node
sudo apt-get install -y nodejs

# 3. Verify installation
node --version  # Should show v24.x.x from /usr/bin/node

# 4. Restart OpenClaw gateway
openclaw gateway restart

# 5. Verify fix
openclaw doctor --non-interactive
```

**Alternative:** Keep current setup if you prefer managing Node via NVM. The warning is informational, not critical.

---

## Current Doctor Status

```bash
openclaw doctor --non-interactive
```

**Summary:**
- ✅ Memory search: Disabled (no warnings)
- ✅ Telegram: Group policy set to "open"
- ✅ Security: No warnings
- ✅ Obsidian: Configured with helper script
- ⚠️ Node runtime: Using NVM (functional, but may break on upgrades)
- ℹ️ 40 skills missing requirements (normal - install as needed)

---

## Files Modified

1. `/home/theo/.openclaw/openclaw.json` - Config patches applied
2. `/home/theo/clawd/TOOLS.md` - Updated Obsidian section
3. `/home/theo/clawd/scripts/obsidian.sh` - New helper script (2.9KB)
4. `/home/theo/clawd/scripts/obsidian-helper.sh` - Old script (can be deleted)

---

## Next Steps (Optional)

1. **Install system Node** (see "Node Runtime Warning" above) - requires sudo
2. **Test Obsidian integration:**
   ```bash
   bash ~/clawd/scripts/obsidian.sh create "Test/Hello" "# Hello from Zé"
   bash ~/clawd/scripts/obsidian.sh search "hello"
   ```
3. **Configure Brave API** for web search (if needed):
   ```bash
   openclaw configure --section web
   ```

---

Generated: 2026-03-14 16:47 GMT-3
