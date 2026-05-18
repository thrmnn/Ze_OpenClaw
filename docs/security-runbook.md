# Security Runbook — Zé Infrastructure

> Last audit: 2026-04-07 | Auditor: Zé (automated) + Théo (manual)

## Network Topology

```
                    ┌─────────────────────────────────────┐
                    │  Hetzner VPS (ubuntu-8gb-hel1-1)    │
Internet ──────────►│  Public IP: [redacted]               │
                    │                                     │
  Port 22 ─────────►│  SSH (UFW: blocked public,          │
  (blocked by UFW)  │       allowed on tailscale0)        │
                    │                                     │
  Port 80 ──────────►│  nginx (DEFAULT PAGE — disable!)    │
  (open — FIX)      │                                     │
                    │  ┌─ 127.0.0.1:18789 ─ OpenClaw GW  │
                    │  ├─ 127.0.0.1:6333  ─ Qdrant       │
                    │  ├─ 127.0.0.1:8384  ─ Syncthing UI │
                    │  └─ 0.0.0.0:22000   ─ Syncthing    │
                    └──────────┬──────────────────────────┘
                               │ Tailscale (100.118.51.89)
                               │
                    ┌──────────┴──────────────────────────┐
                    │  Laptop/WSL (msi, 100.104.205.62)   │
                    │  ├─ Claude Code (local dev)          │
                    │  ├─ Syncthing ←→ VPS                │
                    │  └─ Obsidian (4 vaults)             │
                    └─────────────────────────────────────┘

External services:
  ├─ Telegram API ←→ OpenClaw bot (@Tzinho_lclclawdbot)
  ├─ Anthropic API ←→ Claude Sonnet/Haiku (€20/mo cap)
  ├─ Mission Control ←→ Vercel (mission-control-ruby-zeta)
  ├─ Google APIs ←→ Calendar, Gmail, Drive
  └─ Brave Search API ←→ Web search
```

## Credential Inventory

| Credential | Location | Perms | Rotation |
|------------|----------|-------|----------|
| Anthropic API key | `credentials/anthropic.env` | 600 | Quarterly |
| Claude Code OAuth | `credentials/claude-code.env` | 600 | On breach |
| Google OAuth client | `credentials/google-oauth-client.json` | 600 | Annual |
| Google tokens | `credentials/google-tokens.json` | 600 | Auto-refresh |
| Telegram bot token | `~/.openclaw/openclaw.json` | 600 | On breach |
| Brave Search API | `~/.openclaw/openclaw.json` | 600 | Quarterly |
| OpenAI API key | `credentials/openai-api-key.txt` | 600 | Quarterly |
| Convex API key | `credentials/convex-mission-control.env` | 600 | Annual |
| GitHub SSH keys | `~/.ssh/id_ed25519`, `~/.ssh/id_rsa` | 600 | Annual |
| Trello API | `credentials/trello.env` | 600 | Quarterly |
| X/Twitter API | `credentials/x-api.env` | 600 | On breach |

## Monthly Security Checklist

- [ ] `sudo apt update && sudo apt upgrade` on VPS
- [ ] Check `unattended-upgrades` is running: `systemctl status unattended-upgrades`
- [ ] Review UFW rules: `sudo ufw status`
- [ ] Check for unexpected listening ports: `ss -tlnp`
- [ ] Verify credential permissions: `ls -la ~/clawd/credentials/ ~/.openclaw/openclaw.json`
- [ ] Review OpenClaw gateway memory usage: `systemctl --user status openclaw-gateway`
- [ ] Check fail2ban bans: `sudo fail2ban-client status sshd`
- [ ] Review Syncthing device list: `curl -s http://localhost:8384/rest/config/devices`
- [ ] Check Telegram bot allowlist in `openclaw.json`
- [ ] Verify €20/mo Extra Usage cap at claude.ai/settings/usage
- [ ] Rotate any credentials past their rotation date

## Incident Response

### Bot Token Compromised
1. Revoke token via @BotFather on Telegram: `/revoke`
2. Generate new token: `/newbot` or `/token`
3. Update `~/.openclaw/openclaw.json` → `channels.telegram.botToken`
4. Restart gateway: `systemctl --user restart openclaw-gateway`
5. Review journal for unauthorized messages: `journalctl --user -u openclaw-gateway | grep telegram`

### API Key Compromised
1. Rotate at the provider's console (Anthropic, Google, etc.)
2. Update the credential file in `~/clawd/credentials/`
3. Restart dependent services
4. Check billing dashboard for unauthorized usage

### VPS Breach Suspected
1. **Do NOT delete evidence.** Preserve logs first.
2. `last -20` — check login history
3. `journalctl --since "24 hours ago"` — review system journal
4. `ss -tlnp` — check for unexpected listeners
5. `find / -mtime -1 -type f 2>/dev/null | head -50` — recently modified files
6. If confirmed: snapshot the disk, wipe, redeploy from git

### Session Burn (cost incident)
1. Stop gateway: `systemctl --user stop openclaw-gateway`
2. Check session sizes: `ls -lhS ~/.openclaw/agents/*/sessions/*.jsonl`
3. Rotate bloated sessions: `mv <file> <file>.reset.manual.$(date +%Y-%m-%d)`
4. Check sentinel logs: `tail ~/clawd/logs/ze-*.log`
5. Restart: `systemctl --user start openclaw-gateway`

## Hardening TODO

- [ ] Disable nginx: `sudo systemctl stop nginx && sudo systemctl disable nginx`
- [ ] Close port 443: `sudo ufw delete allow 443`
- [ ] Install fail2ban: `sudo apt install fail2ban && sudo systemctl enable fail2ban`
- [ ] Enable unattended-upgrades: `sudo apt install unattended-upgrades && sudo dpkg-reconfigure -plow unattended-upgrades`
- [ ] Set journal retention: `sudo journalctl --vacuum-size=200M`
- [ ] Encrypted credential backup to a second location
