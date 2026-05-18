# VPS Runbook — Zé System

> Last updated: 2026-04-04 | This is your recovery doc. If Zé is down, start here.

---

## 1. Access — SSH into the VPS

### Via Tailscale (preferred — works anywhere)
```bash
ssh theo@100.118.51.89
```

### Add a laptop alias (one-time setup)
Add to `~/.ssh/config` on your laptop:
```
Host vps
  HostName 100.118.51.89
  User theo
```
Then just: `ssh vps`

### If Tailscale is down
Use the Hetzner public IP (check Hetzner console) or the **web console**:
- https://console.hetzner.cloud → select server → "Console"
- Login: `theo` + your VPS password

### Check you're on the right machine
```bash
hostname        # ubuntu-8gb-hel1-1
tailscale status  # shows both machines connected
```

---

## 2. System Overview

```
[Your Laptop]                    [Hetzner VPS — ubuntu-8gb-hel1-1]
     |                                         |
     | Tailscale (100.118.51.89)               |
     |←————————————————————————————————————————|
     |                                         |
  claude TUI                     OpenClaw Gateway (:18789)
  (direct API)                          |
                                   Telegram Bot
                                  (@Tzinho_lclclawdbot)
                                         |
                                       Zé 😌
```

**Key rule:** Only the VPS runs the OpenClaw gateway. Never start it on your laptop or Telegram will break.

---

## 3. OpenClaw Gateway

### Check status
```bash
export PATH="$HOME/.nvm/versions/node/v24.14.0/bin:$PATH"
openclaw gateway status
```

### Start / Stop / Restart
```bash
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
```

### As a systemd service (survives reboots)
```bash
systemctl --user status openclaw-gateway
systemctl --user restart openclaw-gateway
journalctl --user -u openclaw-gateway -f   # live logs
```

### Key facts
- Version: 2026.4.2
- Port: 18789 (loopback only)
- Config: `~/.openclaw/openclaw.json`
- Config backup: `~/.openclaw/openclaw.json.bak.YYYY-MM-DD`
- Node: `/usr/bin/node` (system Node 24 — NOT NVM)
- Telegram bot: @Tzinho_lclclawdbot
- Watchdog: `~/clawd/watchdog.sh` runs every 2min via crontab, auto-restarts if down

### CRITICAL — editing the config
```bash
# 1. Always backup first
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y-%m-%d)

# 2. Edit
nano ~/.openclaw/openclaw.json

# 3. Validate JSON before restarting
python3 -c "import json; json.load(open('/home/theo/.openclaw/openclaw.json')); print('JSON valid')"

# 4. Restart
systemctl --user restart openclaw-gateway

# 5. Verify
openclaw gateway status
```

---

## 4. Key Paths

```
~/.openclaw/openclaw.json          Main OpenClaw config
~/.openclaw/openclaw.json.bak.*    Config backups
~/.config/systemd/user/            Systemd service files
~/.config/qmd/index.yml            QMD memory index config
~/.ssh/github_theoh                GitHub SSH key (theoh-io account)
~/.ssh/github_thrmnn               GitHub SSH key (thrmnn account)
~/.ssh/config                      SSH host aliases

~/clawd/                           Main workspace (git: thrmnn/Ze_OpenClaw)
~/clawd/MEMORY.md                  Hot context injected every session
~/clawd/memory/                    Daily logs + topic files
~/clawd/memory/topics/             Long-form topic files (projects, rules, etc.)
~/clawd/credentials/               API keys (NOT in git)
  anthropic.env                    Anthropic API key (no credits — use Claude CLI)
  claude-code.env                  Claude Code OAuth token
  google-tokens.json               Gmail/Calendar/Drive OAuth
~/clawd/scripts/                   Utility scripts
~/clawd/docs/                      Documentation (this file)
~/clawd/logs/                      Watchdog + cron logs
~/clawd/watchdog.sh                Gateway watchdog script

~/obsidian-vaults/                 Obsidian vaults (Syncthing sync)
  Ob_Research_Vault/               Papers, CERN, science
  Ob_Business_Vault/               Jobs, agency, website
  Ob_Perso_Vault/                  Daily notes, health, trading
  Ob_Robotics_Vault/               Zé system, productivity

~/clawd/job-pipeline/              Job application system
  tracker.db                       SQLite application tracker
  discovery/discover.py            Position radar script
~/projects/website/                Personal website (thrmnn.github.io)
~/projects/ai-agency/mvp/          AI agency RAG demo
~/clawd/mission-control/           Mission Control dashboard
```

---

## 5. GitHub SSH Setup

Two accounts, two keys:

| Account | Host alias | Key | Used for |
|---------|-----------|-----|---------|
| `theoh-io` | `github-theoh` | `~/.ssh/github_theoh` | Personal |
| `thrmnn` | `github-thrmnn` | `~/.ssh/github_thrmnn` | Papers, website, Ze_OpenClaw |

```bash
# Test connections
ssh -T git@github-theoh    # → "Hi theoh-io!"
ssh -T git@github-thrmnn   # → "Hi thrmnn!"

# Push clawd config
cd ~/clawd && GIT_SSH_COMMAND="ssh -i ~/.ssh/github_thrmnn" git push origin master
```

---

## 6. Syncthing (Vault Sync)

Syncthing keeps Obsidian vaults two-way synced between laptop and VPS.

```bash
systemctl --user status syncthing
systemctl --user restart syncthing

# VPS device ID
syncthing --device-id
# 4VCOD2D-4GPEJO7-GASC7Y6-KJ7C5GX-NNP3CWT-UVLMJRO-6TLB4TW-6JKL2QL

# Folder status
syncthing cli show connections
```

---

## 7. Memory & QMD

QMD powers semantic search across all memory files and Obsidian vaults.

```bash
export PATH="$HOME/.bun/bin:$PATH"

qmd status                          # check index health
qmd update && qmd embed             # reindex everything
qmd search "query" -n 3             # search directly
```

Collections indexed:
- `workspace` → `~/clawd/*.md` (11 files)
- `memory` → `~/clawd/memory/**/*.md` (51 files)
- `vault-research/business/perso/robotics` → all 4 vaults (207 files)
- **Total: 270 files, 6.6MB index**

Config: `~/.config/qmd/index.yml`

---

## 8. Troubleshooting

### Zé not responding on Telegram
```bash
ssh vps
export PATH="$HOME/.nvm/versions/node/v24.14.0/bin:$PATH"
openclaw gateway status
# If not running:
systemctl --user restart openclaw-gateway
# Check logs:
journalctl --user -u openclaw-gateway -n 50
```

### Gateway crashes on config edit
```bash
# Restore backup
cp ~/.openclaw/openclaw.json.bak.YYYY-MM-DD ~/.openclaw/openclaw.json
systemctl --user restart openclaw-gateway
```

### Syncthing not syncing
```bash
systemctl --user status syncthing
systemctl --user restart syncthing
# Check for conflicts:
find ~/obsidian-vaults -name "*.sync-conflict*"
```

### VPS out of memory (OOM)
```bash
free -h          # check RAM
ps aux --sort=-%mem | head -10   # find culprit
# Note: no swap configured — add if needed:
# sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
# sudo mkswap /swapfile && sudo swapon /swapfile
```

### Job pipeline errors
```bash
cd ~/clawd/job-pipeline
python3 discovery/discover.py --dry-run
python3 -m tracker.cli status
```

---

## 9. Quick Reference

```bash
# SSH in
ssh theo@100.118.51.89

# Is Zé alive?
openclaw gateway status

# Restart Zé
systemctl --user restart openclaw-gateway

# Check crons
openclaw cron list

# Memory search
export PATH="$HOME/.bun/bin:$PATH" && qmd search "query" -n 3

# Sync vaults
systemctl --user status syncthing

# Git push clawd
cd ~/clawd && GIT_SSH_COMMAND="ssh -i ~/.ssh/github_thrmnn" git push origin master

# Morning brief test
cd ~/clawd && source credentials/claude-code.env && python3 scripts/morning-brief-v2.py --dry-run
```
