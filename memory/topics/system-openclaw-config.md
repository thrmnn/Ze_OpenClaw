# System — OpenClaw Configuration

> Extracted from MEMORY.md on 2026-04-02

## Gateway
- Running as systemd user service: `~/.config/systemd/user/openclaw-gateway.service`
- Port: 18789 (loopback only: 127.0.0.1)
- Node: `/usr/bin/node` (system Node 24, migrated off NVM on 2026-03-23)
- Env vars set: `NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache`, `OPENCLAW_NO_RESPAWN=1`
- Commands: `openclaw gateway status|start|stop|restart`

## Doctor Fixes Applied (2026-03-14 + 2026-03-23)
- Memory Search: disabled built-in, using QMD instead
- Telegram Group Policy: changed to "open"
- Node Runtime: migrated from NVM to system Node 24
- Session locks: cleaned (store was already clean)
- MEMORY.md: archived pre-March entries → 29% size reduction

## QMD Memory Backend
- Powers `memory_search` and `memory_get` tools
- Manual: `export PATH="$HOME/.bun/bin:$PATH" && qmd query "terms" -n 3`
- Refresh: `qmd update && qmd embed`
- Status: `qmd status`

## Telegram
- Bot: @Tzinho_lclclawdbot
- Connected account: default
- Channel: telegram, chat_id: 8158798678

## Known Issues
- OpenClaw version: 2026.3.13 (update to 2026.3.23-2 pending)
- No swap configured on VPS (OOM risk if gateway grows)
