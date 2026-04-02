# MEMORY — Hot Context
> Last updated: 2026-04-02 | Injected every session. Keep under 5000 chars.
> Full topic files: ~/clawd/memory/topics/ | Daily logs: ~/clawd/memory/YYYY-MM-DD.md

---

## Identity

- **Théo** (Alessandro Hermann) — French-Brazilian robotics/AI engineer, Sao Paulo, Brazil time
- **Zé** — personal AI assistant running on Hel1 VPS via OpenClaw + Telegram (@Tzinho_lclclawdbot)
- **Language:** Théo speaks French or English; all files/notes/code written in English
- **Tone:** calm, sharp, low-ego operator. No filler. Precise over verbose.
- **Strategy split:** Théo handles research manually (LAI, Brisa+). Zé runs everything else.
- **Task format:** always label tasks A/B/C… so Théo can say "done with A/C"

---

## Active Projects

| Project | Location | Status | Next Action |
|---------|----------|--------|-------------|
| LAI Paper | `/home/theo/lai_paper` | ⚠️ Overdue (was Mar 21) | Push to origin + submit |
| Brisa+ Paper | `/home/theo/brisa_paper` | 🟡 In progress | CFD pipeline, deadline June 2026 |
| Job Pipeline | `~/clawd/job-pipeline/` | 🟡 13 apps queued, 0 submitted | Run process_queue.py |
| Morning Brief v2 | `~/clawd/scripts/morning-brief-v2.py` | ✅ Live, cron 6:50am weekdays | Monitor daily output |
| Personal Website | `~/projects/website/` | ✅ Live at thrmnn.github.io | Push updates via git |
| Mission Control | `~/clawd/mission-control/` | ✅ Live at mission-control-ruby-zeta.vercel.app | Fix write mutations |
| AI Agency MVP | `~/projects/ai-agency/mvp/` | 🟡 Maintenance mode | Outreach to French legal-tech |
| PhD Application | `Ob_Business_Vault/Projects/PhD Application/` | 🟡 Plan built | Supervisor outreach by April |

---

## Infrastructure

### Obsidian Vaults (Syncthing two-way sync with laptop)
- `~/obsidian-vaults/Ob_Research_Vault` — papers, CERN, science
- `~/obsidian-vaults/Ob_Business_Vault` — jobs, agency, website, branding
- `~/obsidian-vaults/Ob_Robotics_Vault` — Zé system, productivity
- `~/obsidian-vaults/Ob_Perso_Vault` — daily notes, health, trading

### VPS
- Host: ubuntu-8gb-hel1-1 | Tailscale IP: 100.118.51.89
- SSH from laptop: `ssh theo@100.118.51.89` or `ssh vps`
- OpenClaw gateway: running on `/usr/bin/node` (system Node 24), port 18789

### GitHub (two accounts — SSH config on laptop only, NOT on VPS yet)
- `theoh-io` → host alias `github-theoh-io` → key `id_ed25519`
- `thrmnn` → host alias `github-thrmnn` → key `id_rsa`
- Default `github.com` maps to `theoh-io` — use aliases for thrmnn repos

### Key Paths
- Credentials: `~/clawd/credentials/` (google-tokens.json, anthropic.env, claude-code.env)
- Job tracker DB: `~/clawd/job-pipeline/tracker.db`
- Morning brief modules: `~/clawd/scripts/brief-modules/`
- Claude CLI auth: `source ~/clawd/credentials/claude-code.env`

---

## Standing Rules

### /today Workflow
- Read daily note + all INTERVIEW files → process → update daily note with actionable intel
- INTERVIEW files: `{vault}/Projects/{project}/INTERVIEW - Current Status.md`
- Daily note: `Ob_Perso_Vault/Daily/YYYY-MM-DD.md`
- Always add "Zé's read" section with concrete observations, flag blockers explicitly

### Academic Papers
- NEVER modify scientific claims without Théo's approval
- NEVER change citations/figures without approval
- Always pre-flight check (clean git tree) before any edit
- Full rules: `~/clawd/memory/topics/rules-academic-papers.md`

### Intermittent Fasting
- Théo eats in a 12:00–18:00 window (no breakfast)
- Adjust nutrition/meal advice accordingly

---

## Broken / Blocked

| Issue | Impact | Fix |
|-------|--------|-----|
| SSH keys not on VPS | Can't push to GitHub from VPS | Add keys + `~/.ssh/config` to VPS |
| Anthropic API key — no credits | Python SDK calls fail | Add credits at console.anthropic.com/billing |
| Nitter blocked (VPS IP) | X/Twitter intel always empty in morning brief | No fix — skip gracefully |
| Mission Control write mutations | Task updates via API unreliable | Investigate Convex mutations |
| OpenClaw update pending | Running 2026.3.13, latest 2026.3.23-2 | Run `openclaw update` |
| No swap on VPS | OOM risk if gateway grows | `sudo fallocate -l 2G /swapfile` |
