# Tools Setup Reference (Detailed)

Moved from TOOLS.md to save context tokens. Search via `memory_search` when needed.

---

## MCP Servers

### Trello
- **Status:** ✓ Connected via Claude Code MCP
- **Package:** @delorenj/mcp-server-trello
- **Credentials:** `credentials/trello.env` (gitignored)
- **Wrapper:** `credentials/trello-mcp.sh` loads env and runs MCP server

### Filesystem
- **Status:** ✓ Connected via Claude Code MCP
- **Scope:** /home/theo/clawd

### Google Workspace
- **Status:** ✓ Connected via MCP AND Python API
- **Package:** @alanse/mcp-server-google-workspace
- **Credentials:** `credentials/google-oauth-client.json` + `credentials/google-tokens.json`
- **Features:** Gmail, Drive, Sheets (57 tools), Calendar
- **Python:** `source venv-google/bin/activate` then use googleapiclient

---

## QMD (Quick Markdown Search)

**Now integrated as OpenClaw memory backend** — `memory_search` and `memory_get` use QMD automatically.

- **Binary:** `~/.bun/bin/qmd`
- **Index:** auto-managed by OpenClaw (updates every 5 min + on boot)
- **Collections:** memory files + workspace + Obsidian vault
- **Manual commands still work:**
  ```bash
  export PATH="$HOME/.bun/bin:$PATH"
  qmd query "search terms" -n 3
  qmd status
  qmd update && qmd embed
  ```

---

## OpenClaw Skills

### GitHub (🐙) — needs `gh auth login`
### Notion (📝) — needs API token in `credentials/notion.env`
### Sag/ElevenLabs (🗣️) — needs API key in `credentials/elevenlabs.env`

### Trello (📋)
- **Board:** "Zé Dashboard" (ID: 699dc91ad27a2301f3acc5f1)
- **Philosophy:** Trello = execution, Obsidian = source of truth
- **Lists:** Inbox → Today → Next Actions → In Progress → Waiting → Projects → Done
- **Rules:** Max 5 Today, 3 In Progress, one Next Action per project
- **Scripts:** `scripts/today-command-v2.sh`, `scripts/trello-synthesis.sh`

### Obsidian (💎)
- **Vault (WSL):** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault`
- **Structure:** PARA method (Projects/Areas/Resources/Archive)
- **Script:** `scripts/obsidian.sh` (create/search/read/append)
- **Sync:** `scripts/obsidian-trello-sync.sh`
- **Docs:** `docs/OBSIDIAN-SECOND-BRAIN.md`

---

## Mission Control Dashboard
- **URL:** https://mission-control-ruby-zeta.vercel.app/
- **Status:** Partially working (activity logging ✅, mutations ⚠️)
- **Scripts:** `scripts/mission-control-test.sh`, `scripts/mission-control-log.sh`

---

## AI Agency Project
- **Script:** `scripts/ai-agency-update.sh`
- **Structure:** EXECUTION ROADMAP.md, project.md, tasks.md, notes.md
