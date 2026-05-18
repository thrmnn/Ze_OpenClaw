# Checkpoint — 2026-04-27 (gateway-revival session)

> Resume marker for the OpenClaw gateway revival + cost-control work.
> Updated 2026-04-29 after CEO review + parallel agent investigation (plugin SDK, 9-job analysis, Phase 2 design).

## What's done

- **Diagnosed gateway downtime.** Stopped 2026-04-10 10:33 UTC via clean SIGTERM after Anthropic returned `out of extra usage` for ~80 min. €20/mo Extra Usage cap exhausted in 5 days (April 5 → April 10). Volume burn from 9 Sonnet-on-main-session crons.
- **Burn-cause identified.** 9 of 28 enabled crons use `agent: main` (Sonnet) + `sessionTarget: main` (shared, growing). The other 21 use `cron-worker` (Haiku) + isolated — those are cheap.
- **Sentinel scripts fixed locally** (`ze-circuit-breaker.sh`, `ze-cost-proxy-sentinel.sh`) — bash unbound-var bug. Will Syncthing-sync to VPS.
- **Anthropic Extra Usage cap topped up another €20** (Théo, on phone).
- **openclaw updated** 2026.4.2 → 2026.4.25. Both `openclaw.json` and `jobs.json` survived intact (0-line diff). Configs backed up to `*.pre-update.2026-04-27`.
- **Plugin SDK audit done** (Agent A, 2026-04-29). Critical finding: **`prompt:before` does NOT exist**. Available events: `agent:bootstrap`, `gateway:startup`, `message:{received,sent,preprocessed,transcribed}`, `command:{new,reset,stop}`, `session:*`. No event fires synchronously before an LLM call. Plugin-as-cost-guard design retired in favor of sentinel upgrade.
- **OpenClaw already ships cost-tracking primitives:** `estimateUsageCost()`, `ModelCostConfig` (input/output/cacheRead/cacheWrite per model), `AssistantUsageSnapshot.usage`, `cron.retry.retryOn`, `session.parentForkMaxTokens`, `session.maintenance.maxDiskBytes`. Missing piece is enforcement, which the upgraded sentinel handles.
- **9-job triage done** (Agent B, 2026-04-29). Verdicts below.
- **CEO review run** (2026-04-29). Mode: SELECTIVE EXPANSION. Approach: C (triage first, flip survivors). Phase 2: γ (sentinel upgrade, no plugin).

## Current VPS state

- Gateway: **stopped** (do NOT restart until Phase 1 done)
- Version: 2026.4.25 (aa36ee6)
- 6 ze-* user systemd timers firing on cadence
- Morning brief (deterministic, no LLM): firing daily 10:30 UTC
- All 28 jobs.json crons fire into nothing while gateway is down

## Plan (after CEO review)

**Phase 0 — Anthropic console cap.** ✅ Done (€20 topped up).

**Phase 1 — Triage + per-job action (~30-45 min).**

Engagement triage first: scroll back through Telegram bot history (chat 8158798678) for the 9 expensive crons. Mark each as ENGAGED (read/replied/acted on) or UNREAD/IGNORED in last 30 days. Disable any UNREAD outright before flipping survivors.

Per-job action matrix (from Agent B, 2026-04-29):

| # | Job | Action |
|---|-----|--------|
| 1 | Obsidian Morning Routine (08:00) | **CLEAN_FLIP** — agentId=cron-worker, sessionTarget=isolated, payload.kind=agentTurn, add `delivery.target.chatId: "8158798678"`. Stagger to 08:01 to avoid #4 collision. |
| 2 | End-of-Day Review (17:50 Mon-Fri) | **PROMPT_REWRITE + flip** — replace "is Théo active in session" with file-mtime probe on `~/.openclaw/sessions/main.json`; replace "summarize what got done today" with "read today's daily note + files modified in last 24h via `find -mtime -1`". Then flip identifiers. |
| 3 | Sunday Mini-Review (Sun 20:00) | **PROMPT_REWRITE + flip** — same activity-check fix. Add streak count from `memory/check-ins/YYYY-MM.md`. Flip identifiers. |
| 4 | Health Morning Log (08:00) | **PROMPT_REWRITE + flip** — replace form-style with rotating question per CLAUDE.md (Mon/Thu training, Tue/Fri sleep, Wed avoidance, Sat wins, Sun weekly summary). Flip identifiers. Stays at 08:00 (Obsidian moves to 08:01). |
| 5 | Weekly Kickoff (Mon 09:00) | **CLEAN_FLIP** — same identifier flips + add chatId. |
| 6 | Friday Weekly Review + Content Draft (Fri 18:00) | **KEEP_SONNET_ISOLATED** — agentId stays `main` (Sonnet) but `sessionTarget: main → isolated`, `payload.kind: systemEvent → agentTurn`. Removes shared-session bloat without losing content quality. 1×/week is bounded. Add chatId. |
| 7 | Weekly Digest Email (Sun 19:00) | **DEMOTE_SHELL** — payload is `python3 weekly-digest.py`. Move to systemd user timer or system crontab. Delete openclaw cron entry. Zero LLM. |
| 8 | Weekly Life Admin (Sun 10:00) | **DEMOTE_SHELL** — VPS prompt confirmed (2026-04-29): 80% static checklist (FRIDAY CLEAN / GROOMING / MEAL PREP / HOUSE) + one file probe (Batch-Cooking-Guide.md). Zero reasoning. Replace with shell: templated Telegram message + grep for "did meal-prep happen this week" via Batch-Cooking-Guide mtime. ~30 min. |
| 9 | Position Radar Scan (disabled) | **DELETE** — already disabled, redundant with active Haiku-Position Radar Daily Scan. Just remove from jobs.json. |

Workflow:
1. `cp ~/.openclaw/cron/jobs.json ~/.openclaw/cron/jobs.json.pre-flip.2026-04-29` (backup)
2. Engagement triage of all 9 (Telegram history skim, ~10 min)
3. Read #8 prompt from VPS
4. Apply matrix above
5. Validate JSON: `python3 -m json.tool ~/.openclaw/cron/jobs.json`
6. Migrate #7 to systemd timer

**Phase 1.5 — Two auto-included config tweaks (~5 min).**

Edit `~/.openclaw/openclaw.json` on VPS (with backup):
- `cron.retry.retryOn` — exclude `"rate_limit"` from retry list. Stops 3x retry burning when cap is exhausted.
- `session.parentForkMaxTokens: 50000` — caps how much parent transcript a forked session inherits. Defense-in-depth against shared-session bloat regardless of Phase 1.

Validate JSON, restart gateway.

**Phase 2 — Real-usage sentinel upgrade (~2 hours).**

Replace `ze-cost-proxy-sentinel.sh`'s byte-stat estimator with real `usage.input_tokens + output_tokens` reads from session JSONLs. OpenClaw already writes per-call usage into session entries (Agent A confirmed). Aggregate by agent + day. Trip thresholds:
- WARN per agent at 50% of daily budget (Telegram once/day)
- TRIP at 100% — `systemctl --user stop openclaw-gateway` + Telegram alert

Initial budgets:
- `main` agent: 50K tokens/day
- `cron-worker` agent: 200K tokens/day

Reuse `cron_budget.db` SQLite schema. The morning brief's existing `report` action keeps working.

No plugin needed (no synchronous pre-call event exists in OpenClaw). Reactive enforcement is fine because Phase 1 already removed the runaway shared-session burn-mode.

**Phase 3 — Observe + iterate (open-ended).**

Restart gateway. Watch sentinel logs for 1-2 weeks. Adjust budgets based on actual usage. Decide per-job whether further demotions to shell make sense (especially #4 Health Morning Log — a shell wrapper picking the rotating question + Haiku call to send the question only is cheaper than full Haiku synthesis).

**Phase 4 — Deferred (TODOS.md).**
- Per-cron cost dashboard (daily Telegram digest of yesterday's costs by job)
- /triage Telegram command (auto cron value scoring + one-tap disable)

## Gateway restart sequence (when Phase 1 + 1.5 done)

```bash
ssh hetzner
source ~/.nvm/nvm.sh && nvm use 24.14.0
systemctl --user start openclaw-gateway
journalctl --user -u openclaw-gateway -f | grep -E 'rate_limit|out of extra|isError'
```

If clean for 5 min, send a Telegram test to @Tzinho_lclclawdbot. Confirm reply lands. If sentinel reports turns happening + spend within budget, success.

## Open questions for next session

1. Read #8 Weekly Life Admin prompt from VPS to confirm DEMOTE_SHELL vs CLEAN_FLIP.
2. Engagement triage results — which of the 9 jobs survive? Could collapse the matrix substantially.
3. Verify €20 Anthropic cap is actually being enforced via web console (Théo set on Android — cross-check at first burn-rate observation).
4. Verify `better-sqlite3` (or any sqlite binding) availability in openclaw runtime if we ever want to revisit β plugin path. Otherwise sentinel uses `sqlite3` CLI subprocess, which is fine.

## Files touched this session

- `~/clawd/scripts/ze-circuit-breaker.sh` — fixed unbound var bug
- `~/clawd/scripts/ze-cost-proxy-sentinel.sh` — same fix; will be upgraded to real-usage in Phase 2
- VPS: `~/.openclaw/openclaw.json.pre-update.2026-04-27` (backup)
- VPS: `~/.openclaw/cron/jobs.json.pre-update.2026-04-27` (backup)
- VPS: openclaw upgraded to 2026.4.25
- `~/clawd/docs/checkpoint-2026-04-27.md` — this file (updated 2026-04-29)
- `~/clawd/PLUMBING-TODO.md` — added P2 items for Phase 4 deferrals

## Reference: agent investigation outputs (2026-04-29)

- **Agent A** (plugin SDK inventory): events list, config knobs, bundled plugins. `prompt:before` does NOT exist; cost primitives already shipped.
- **Agent B** (9-job triage): per-job verdicts in matrix above. Local jobs.json is stale by 25 days; live VPS read needed for #8.
- **Agent C** (Phase 2 plugin design): superseded by Phase 2-γ decision. Skeleton retained for future reference if `prompt:before` ever ships in OpenClaw.
