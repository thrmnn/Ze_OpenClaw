# TOOLS.md - Local Notes

Quick reference for environment-specific setup. Full details: `docs/tools-setup-reference.md`

## Quick Access

- **Gmail:** `cd ~/clawd && source venv-google/bin/activate && python3 scripts/send-email.py`
- **Obsidian vaults:** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/`
  - `Ob_Research_Vault` (academic papers, CERN, science)
  - `Ob_Business_Vault` (jobs, AI agency, website, branding)
  - `Ob_Robotics_Vault` (Zé system, productivity, tools)
  - `Ob_Perso_Vault` (daily notes, health, trading, personal)
- **Obsidian helper:** `bash ~/clawd/scripts/obsidian.sh --vault <name> <command>`
- **Trello board:** "Zé Dashboard" (ID: 699dc91ad27a2301f3acc5f1)
- **Trello synthesis:** `bash ~/clawd/scripts/trello-synthesis.sh`
- **Voice transcribe:** `python3 scripts/audio-transcribe-local.py <file> --model tiny`
- **Email account:** zeclawd@gmail.com

## Memory (QMD)

Now integrated as OpenClaw memory backend. `memory_search` and `memory_get` tools use QMD automatically.
- Manual: `export PATH="$HOME/.bun/bin:$PATH" && qmd query "terms" -n 3`
- Status: `qmd status`
- Refresh: `qmd update && qmd embed`

## Connected Services

| Service | Status | Notes |
|---------|--------|-------|
| Anthropic API | ✅ | claude-sonnet-4-6 default |
| Gmail/Drive/Calendar | ✅ | OAuth, auto-refresh |
| Trello MCP | ✅ | Board: Zé Dashboard |
| Brave Search | ✅ | Web search enabled |
| Obsidian | ✅ | PARA vault, morning routine |
| QMD Memory | ✅ | Backend for memory_search |
| Notion | ⚙️ | Needs API token |
| ElevenLabs TTS | ⚙️ | Needs API key |
| GitHub CLI | ⚙️ | Needs `gh auth login` |

## Mission Control

- **URL:** https://mission-control-ruby-zeta.vercel.app/
- **Status:** Partial (activity logging ✅, mutations ⚠️)
