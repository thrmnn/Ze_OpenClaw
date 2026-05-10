# MEMORY — Hot Context
> Last updated: 2026-05-09 (09:07 BRT) | Injected every session. Keep under 5000 chars.
> Full topic files: ~/clawd/memory/topics/ | Daily logs: ~/clawd/memory/YYYY-MM-DD.md

---

## Identity

- **Théo** (Alessandro Hermann) — French-Brazilian robotics/AI engineer, based in **Rio de Janeiro** (family base in São Paulo), Brazil time
- **Zé** — personal AI assistant running on Hel1 VPS via OpenClaw + Telegram (@Tzinho_lclclawdbot)
- **Language:** Théo speaks French or English; all files/notes/code written in English
- **Tone:** calm, sharp, low-ego operator. No filler. Precise over verbose.
- **Strategy split:** Théo handles research manually (LAI, Brisa+). Zé runs everything else.
- **Task format:** always label tasks A/B/C… so Théo can say "done with A/C"

---

## Active Projects

| Project | Location | Status | Next Action |
|---------|----------|--------|-------------|
| LAI Paper | `/home/theo/lai_paper` | 🔴 **49 DAYS OVERDUE** (deadline Mar 21) | Review 11 modified files + tree count fix + commit + co-author sign-offs. Target submit TODAY. |
| AI Agency MVP | `~/projects/ai-agency/mvp/` | 🔴 **49 DAYS OVERDUE** (deadline Mar 21) | .env deploy + docker test + Loom demo + 3 legal-tech DMs (Hyperlex, Leeway, Predictice) TODAY |
| Brisa+ Paper | `/home/theo/brisa_paper` | 🟡 In progress | CFD pipeline, deadline June 2026 |
| Job Pipeline | `~/clawd/job-pipeline/` | 🟡 Production ready | Submit Apptronik (83/100) + Position Radar scan (14→24 companies). 13 apps ready. |
| Personal Website | `~/projects/website/` | 🟡 70% done | Content sprint: 3 project descriptions + screenshots + headshot |
| Morning Brief v2 | `~/clawd/scripts/morning-brief-v2.py` | ✅ Live, cron 6:50am weekdays | Monitor daily output |
| Mission Control | `~/clawd/mission-control/` | ✅ Live at mission-control-ruby-zeta.vercel.app | Fix write mutations |
| PhD Application | `Ob_Business_Vault/Projects/PhD Application/` | 🟡 Plan built | Supervisor outreach by April |
| HP Studio (Hermann & Postingel) | `Ob_Business_Vault/Wiki/sources/App Development Studio.md` | 🟡 Ideation | 5 app ideas by Fri Apr 11 |

### People (new)
- **Michiel** — MIT SCL Amsterdam, LAI collaborator. Weekly meetings.
- **Mateo Postingel** — Italian designer, MIT SCL Rio, co-founder HP Studio (him frontend, Théo backend)
- **Théo's brother** — in France. Weekly call reminder active, target slot 13-14h BRT = 18-19h CEST. Remind until confirmed.
- **Antoine Dubos** — friend, weekly Monday meeting (startup/freelancing accountability)
- **Lucas Gobati** — ETH Zürich, Brisa+ microclimate simulations. Hard weekly deadline: show results every Wednesday morning.

### Standing Rules (new)
- ⚠️ **Project sprawl guard:** Théo tends to start too many projects. Flag when new projects emerge. Push back on parallelization.
- **Revenue:** MIT SCL salary (no fixed contract) → transitioning to freelance + entrepreneurship
  - Freelance starting from scratch: rebrand LinkedIn → Fiverr/Malt registration
  - Antoine Dubos Monday meetings: secret project (do not ask)
- **Three pillars:** Santé / Business / Recherche
- **Identity anchors** (use as decision filters when Théo faces a choice or reports a struggle):
  - Santé: "I'm someone who shows up for their body consistently"
  - Business: "I'm someone who ships, not someone who plans"
  - Recherche: "I'm someone who finishes what they start"
- **Health Admin Cadence:** Monthly check (1st Sunday) — doctor/dentist appointments, vitamin stock, medical tasks
- **Measurement Cadence:** Weekly (Sundays) — weight, body fat %, training volume
- **Last health admin check:** 2026-05-04 — DETRAN pending, doctor/dentist not scheduled, supplements not logged
- **⚠️ CRITICAL BLOCKER:** LAI Paper + AI Agency both 49 days overdue (deadline: March 21). May 9 is the breaking point. Academic obligation #1 (LAI) + Revenue #2 (Agency + Job Pipeline). TODAY IS THE DAY.

### Admin Reminders (remind until done)
- [ ] Équivalence permis de conduire français → brésilien (DETRAN SP) — **Last checked: 2026-05-04, pending since April 5** [LOW PRIORITY — defer to after May 9 sprint]
- [ ] Doctor appointment — **Not scheduled, last visit unknown** [LOW PRIORITY — defer to after May 9 sprint]
- [ ] Dentist appointment — **Not scheduled, last visit unknown** [LOW PRIORITY — defer to after May 9 sprint]
- [ ] Vitamin/supplement stock audit — **Not logged, reorder threshold unknown** [LOW PRIORITY — defer to after May 9 sprint]

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

### Gateway Config Rule
- ALWAYS backup → validate JSON → restart when editing openclaw.json
- Backup: `cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak.$(date +%Y-%m-%d)`
- Watchdog (`watchdog.sh`) disabled — replaced by systemd timers

### Infra: Cron & Timers (VPS runtime, verified 2026-04-05 22:22 UTC)
- **cron-worker agent**: isolated OpenClaw agent handling scheduled task dispatch
- **Systemd user timers**: 5 `ze-*` timers on VPS, all firing on cadence
  (circuit-breaker 2m, burn-sentinel 1h, session-sentinel 2×/day, session-rotate daily 04 UTC, morning-brief daily 10:30 UTC)
- **mc-sync-agents**: throttled 2 min → 30 min; still in error state (see PLUMBING-TODO.md P1)
- **VPS crontab**: empty (no watchdog, no native crons — all via openclaw + systemd)
- **Desktop crontab**: still has dead `watchdog.sh */2` entry (harmless; VPS is runtime)
- **Sentinel patterns**: ze-circuit-breaker + ze-burn-sentinel now catch both
  `rate_limit_error` and `"out of extra usage"` (fixed 2026-04-05 — earlier pattern missed today's 18 rejections)
- **Plumbing backlog**: see `PLUMBING-TODO.md` for the durable TODO list

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
| Nitter blocked (VPS IP) | X/Twitter intel always empty in morning brief | No fix — skip gracefully |
| Mission Control write mutations | Task updates via API unreliable | Investigate Convex mutations |
| No swap on VPS | OOM risk if gateway grows | `sudo fallocate -l 2G /swapfile` |
