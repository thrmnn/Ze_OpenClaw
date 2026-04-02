# Gateway Architecture & Debugging Guide

> Last updated: 2026-03-22

## Overview

Two machines, clear roles:

| Machine | Role | Gateway | Claude TUI |
|---------|------|---------|------------|
| **VPS** (Hel1) | OpenClaw host, Telegram bot | ✅ Running | Available but don't conflict |
| **Local laptop** | Dev environment | ❌ Off | ✅ Use freely |

---

## Architecture

```
Telegram ←→ OpenClaw Gateway (VPS) ←→ Claude (Zé)
                    ↕
              [Hel1 Ubuntu VPS]
              ssh theo@<VPS_IP>

Local Laptop:
  claude (TUI) — direct Anthropic API, no gateway
```

**Rule:** Only one gateway should connect to Telegram at a time. Having two causes message duplication and race conditions.

---

## VPS Access

### SSH into VPS
```bash
ssh theo@<VPS_IP>
# or if you have an alias:
ssh hel1
```

Check your `~/.ssh/config` on your laptop for the host alias and IP.

### Check if you're on VPS
```bash
hostname  # should show hel1 or similar
```

---

## Gateway Management (VPS)

### Check gateway status
```bash
openclaw gateway status
```

### Start / Stop / Restart
```bash
openclaw gateway start
openclaw gateway stop
openclaw gateway restart
```

### View live logs
```bash
# If running as a service:
journalctl -u openclaw -f

# Or check openclaw logs directly:
openclaw gateway status
```

### Gateway config location
```bash
~/.config/openclaw/   # or wherever openclaw stores config
openclaw help         # to find exact paths
```

---

## Local Laptop Dev Setup

On your laptop — **do NOT run the gateway**:

```bash
# Just use Claude Code directly:
claude

# Never run on laptop when VPS gateway is active:
# openclaw gateway start   ← DON'T
```

If you accidentally started the gateway locally and broke Telegram routing:
1. Stop local gateway: `openclaw gateway stop`
2. SSH to VPS and restart there: `openclaw gateway restart`
3. Verify in Telegram (send a message to the bot, it should respond)

---

## Troubleshooting

### Bot not responding on Telegram
1. SSH into VPS
2. `openclaw gateway status` — is it running?
3. If stopped: `openclaw gateway start`
4. If running but broken: `openclaw gateway restart`
5. Check logs for errors

### Can't SSH into VPS
- Try from a different network (firewall issue?)
- Check if VPS is up: ping `<VPS_IP>`
- Hetzner console: https://console.hetzner.cloud — use web console as fallback

### Claude TUI not working on laptop
- Check Anthropic API key: `echo $ANTHROPIC_API_KEY`
- Try: `claude --version` to confirm CLI is installed
- Quota issue: wait ~3 hours for cap reset (shared key)

### Both laptop and VPS fighting over Telegram
Symptoms: messages duplicated, bot responds twice, or doesn't respond at all
Fix:
```bash
# On laptop:
openclaw gateway stop

# On VPS (SSH in):
openclaw gateway restart
```

---

## Key Paths (VPS)

```
~/clawd/                        Main workspace
~/clawd/docs/                   Documentation (this file)
~/clawd/memory/                 Daily logs + heartbeat state
~/clawd/MEMORY.md               Long-term curated memory
~/clawd/scripts/                Utility scripts
~/projects/                     Active projects
  job-pipeline/                 Job application system
  position-radar/               Job discovery
  mission-control/              Dashboard
  website/                      thrmnn.github.io
  ai-agency/mvp/                AI agency RAG demo
```

---

## Quick Reference

```bash
# Is the gateway running?
openclaw gateway status

# Restart everything cleanly
openclaw gateway restart

# SSH to VPS from laptop
ssh hel1   # (or ssh theo@<VPS_IP>)

# Open Claude TUI locally (no gateway needed)
claude

# Check VPS is alive
ping <VPS_IP>
```
