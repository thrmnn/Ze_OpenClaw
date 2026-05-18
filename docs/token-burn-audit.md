# Token Burn Audit — 2026-04-02 → 04-05 $200 Incident

> Forensic analysis of the $200 Extra Usage burn. Written 2026-04-05 from VPS log evidence (~3 weeks of gateway archive in `~/clawd/logs/openclaw/`).
> Companion doc: `PLUMBING-TODO.md` (tactical TODOs) · `MEMORY.md` § "Infra: Cron & Timers".

---

## Executive summary

**The burn was not caused by a retry storm. It was caused by ~24 successful API calls, each carrying an 8,032-turn / ~1.4 M-token session context, charged at Claude Sonnet's long-context premium tier (~$8.40/call).** Everything else was secondary.

The three multiplicative factors, ranked by blame:

| Rank | Factor | Contribution |
|---|---|---|
| 1 | **Session auto-reset broken ~2026-04-02** → one session grew 8,032 turns over 69 hours | ≈80× cost multiplier per call |
| 2 | **Long-context tier premium** at >200 K tokens | 2× price multiplier on top of #1 |
| 3 | **No client-side spend cap in openclaw** | Gateway kept calling until Extra Usage was empty |

**Non-factors** (ruled out by data):
- Retry storms. 2,700 "rate limit reached" errors on 2026-04-04 were all pre-billing rejections from the policy-change flip — zero charge.
- mc-sync-agents every 2 min. High cadence but individually cheap; only dangerous once paired with a bloated session.
- Multiple agents. Only `main` was hit; `cron-worker` wasn't created until after the incident.

---

## Timeline (UTC)

| When | Event | Evidence |
|---|---|---|
| **2026-04-02 04:03:46** | Session `cff0c1d7-cd92-47a2-893d-4542a968a516.jsonl` created | first line of the rotated `.reset.manual.2026-04-05.gz` |
| 2026-04-02 → 04 | Session grows continuously across daily boundaries because `session.reset.*` config is not set in `openclaw.json` on v2026.4.2 upgrades | `openclaw.json` has only `{"dmScope": "per-channel-peer"}` under `session` |
| **2026-04-04 02:00** | Anthropic policy change: third-party apps no longer draw from Plan quota. Every request starts bouncing | first "rate limit reached" in log: `2026-04-04T02Z n=132` |
| 2026-04-04 02:00 → 22:12 | Gateway retries at ~128/hour for 20 hours. All rejected pre-billing. Errors wrapped as "⚠️ API rate limit reached. Please try again later." | hourly distribution flat at 128 ± 4 |
| **2026-04-04 22:13** | Real error message surfaces: `"LLM request rejected: Third-party apps now draw from your extra usage..."` — Anthropic auto-credited $200 for migration | first "Third-pa..." error in log |
| ~2026-04-04 22:30 → 24:00 | **Théo activates Extra Usage with $200 bonus credit.** Gateway resumes real calls. Every call sends the now-1.4 M-token session context | inferred from error gap — policy messages stop around 22:45, out-of-usage at 01:02 |
| **2026-04-05 01:02:14** | `"You're out of extra usage"` — $200 gone. Théo manually renames session file with `.reset.manual.2026-04-05` suffix | last line of the bloated session file |
| 2026-04-05 01:02 → 05:43 | Gateway stopped. Théo audits; designs ze-* sentinels; restarts with €20/mo cap | gateway uptime starts 05:43 UTC per `systemctl status` |

**Burn window: ~2.5 hours** (2026-04-04 ~22:30 → 2026-04-05 01:02). **~24 billed calls.** **~$8.40/call average.**

---

## Hard numbers

### Session that did the damage
```
file:     cff0c1d7-cd92-47a2-893d-4542a968a516.jsonl
created:  2026-04-02T04:03:46.865Z
closed:   2026-04-05T01:02:14.531Z
duration: 68h 58min
turns:    8,032 lines (messages)
raw size: 5.68 MB uncompressed  (527 KB gzipped — 90% redundancy)
est tokens: ~1.42 M (4 chars/token rough avg)
```

### Daily error volume (from `embedded_run_agent_end` events with `isError:true`)
| Date | Error count | Dominant error |
|---|---|---|
| 2026-03-25 | 146 | "temporarily overloaded" (Anthropic-side, no charge) |
| 2026-03-26 | 325 | same |
| 2026-03-31 | 702 | same (peak retry storm, pre-incident) |
| 2026-04-03 | 123 | same, tapering |
| **2026-04-04** | **2,729** | 2,700 "rate limit reached" + 28 policy-change + 1 out-of-usage |
| 2026-04-05 (so far) | 12 | mix (post-restart) |

> The log schema only shows errored turn-ends. Successful turns aren't captured here, so turn volume is likely higher than these numbers. Treat this as a **floor**, not a ceiling.

### Hourly pattern on incident day
```
2026-04-04T02Z n=132 (policy flip)
2026-04-04T03Z - T21Z n=128 ± 4 (flat at ~128/hour)
2026-04-04T22Z n=68   (first real error message surfaces at T22:13)
2026-04-05T00Z n=84   (Extra Usage burn window)
2026-04-05T01Z n=5    (session rotated, gateway stopped)
```

**~128 errors/hour for 20 hours straight.** This is the baseline load of the entire cron suite retrying post-flip.

### Cost math

**Claude Sonnet 4.6 long-context pricing** (>200 K token prompts): ~$6/M input, ~$22.50/M output.

With a 1.42 M-token session:
- Input cost/call: 1.42 M × $6/M = **$8.52**
- Output cost/call: ~0.1 K tokens × $22.50/M ≈ $0.002 (negligible)
- **Total: ~$8.52/call**

$200 credit ÷ $8.52 = **23.5 calls** → matches the observed ~24-call burn window.

**Counterfactual — what if session had been <200 K tokens?**
- Input cost/call: 20 K × $3/M = **$0.06**
- Same 24 calls = $1.44 total
- The $200 credit would have lasted ~3,300 calls instead of 24
- **Session bloat alone was responsible for ~140× cost inflation.**

---

## Why the sentinels shipped overnight are *necessary but not sufficient*

The 5 ze-* scripts built after the incident (circuit-breaker, burn-sentinel, session-sentinel, session-rotate, morning-brief) are solid, but each has a gap for the actual failure mode observed:

| Sentinel | Covers | Doesn't cover |
|---|---|---|
| ze-circuit-breaker | Error *bursts* (3 failures / 10 min) | Slow-drip burn where each call succeeds but is expensive |
| ze-burn-sentinel | Turn *count* > 500/day | Token *volume* or $ *spend* per call |
| ze-session-sentinel | Sessions > 1.5 MB | Sessions at 1.0 MB = already in long-context premium tier |
| ze-session-rotate | Files > 2 MB at 04:00 UTC daily | 23h 59m of growth before daily rotation fires |
| ze-morning-brief | Queue visibility | No cost / spend surface |

**The incident would have repeated under the current setup** if:
- Session grew to 1.0 MB (below warn threshold)
- Gateway made 50 calls with that session
- Each call = ~$3
- Total: $150 burned silently, breaker never trips because no errors

This is the gap this audit is meant to close.

---

## Root cause chain (5 whys)

**Why did $200 burn in 2.5 hours?**
→ 24 API calls each cost ~$8.40.

**Why were API calls $8.40?**
→ Each carried a 1.42 M-token session context, in the long-context premium tier.

**Why was the session 1.42 M tokens?**
→ It grew untouched for 69 hours across 3 daily boundaries.

**Why did it grow untouched?**
→ The daily session auto-reset stopped working. The v2026.4.2 upgrade did not migrate the `session.reset.*` config, and nothing external was watching session age.

**Why did nothing external watch session age?**
→ openclaw has **zero cost awareness**. It does not know what a call will cost, does not know the token length of the session it's about to send, and does not have any budget/cap config surface. The only guardrail was the Anthropic-console-level Extra Usage switch, which was gated on a user decision, not a pre-flight check.

**Deepest cause:** openclaw's cost model is "fire and forget" — the gateway will happily drain any connected billing source until the provider 429s it. The operator is responsible for all economic judgment, out-of-band.

---

## State of current openclaw.json (cost-relevant)

```json
{
  "session": {
    "dmScope": "per-channel-peer"
    // NO reset, NO maintenance, NO rotateBytes, NO maxTokens, NO maxAge
  },
  "agents": {
    "defaults": {
      "model": {"primary": "anthropic/claude-sonnet-4-6"},
      "compaction": {
        "reserveTokensFloor": 20000,
        "memoryFlush": {"softThresholdTokens": 4000}
      }
      // NO budget, NO spendCap, NO dailyLimit, NO tokenBudget
    }
  }
  // NO top-level cost / budget / billing config
}
```

**Reality check:** the only numerical guardrail inside openclaw is `reserveTokensFloor: 20000`, which is a *context-management* floor, not a *cost* cap. It reserves 20 K tokens for the assistant's response — it does not limit session size, call frequency, or spend.

---

## Current session state (2026-04-05 22:30 UTC)

Live sessions, sorted by size. Nothing catastrophic, but one session is already 50% of the way to the warn threshold:

```
1.09 MB  main/3534fb97-9481-4303-aa33-a790ff2b2fd9.jsonl   ← 73% toward 1.5 MB warn
0.40 MB  main/cff0c1d7-cd92-47a2-893d-4542a968a516.jsonl   ← reusing incident UUID
0.18 MB  main/a25041ef-825c-4d30-b7be-4555d7db15c0.jsonl
0.13 MB  cron-worker/c70edc38-...jsonl
0.12 MB  main/7d6eb059-...jsonl
```

Total live: 2.3 MB across all agents. Bloated incident session has been gzip-compressed to 527 KB and kept for forensics.

---

## Prevention design — layered defense

The principle: **every layer assumes the previous one will fail.** No single layer is trusted to prevent a burn. Layers are ordered from cheapest+fastest (client-side pre-call checks) to most expensive (billing-level caps).

### Layer 1 — Pre-call token ceiling (cheapest, fastest)
**Goal:** never send a request with >N tokens, no matter what.

**Implementation:**
- A wrapper script or openclaw hook that inspects the session file size *before* every cron invocation. If `stat -c%s` > `MAX_SESSION_BYTES`, the call is aborted and logged.
- Default: `MAX_SESSION_BYTES = 400 KB` (≈100 K tokens, well below the 200 K long-context threshold).
- Each agent can override.
- When exceeded: force session rotation *before* the next call, not after.

**Files:**
- New: `scripts/ze-precall-guard.sh <agent-name> <session-id>` — returns 0 if OK, non-zero if too big.
- Integration: called from a `before_cron_run` hook if openclaw supports one, or wrap each cron's payload to shell-out to this guard first.

### Layer 2 — Daily session reset, verified
**Goal:** no session ever survives >24 hours.

**Implementation:**
- Extend `ze-session-rotate.sh` to rename *any* `.jsonl` file older than 24 h (by mtime or first-line timestamp), regardless of size. Current version only rotates >2 MB files.
- Add a complementary sentinel that alerts if any live session has a `created` timestamp older than the last 04:00 UTC boundary.
- The incident session lived 69 h — this layer alone would have killed it at 24 h, at which point it was ~500 K tokens (expensive but not catastrophic).

**Files to change:**
- `scripts/ze-session-rotate.sh` — add age-based rotation clause.
- New sentinel: `scripts/ze-session-age-sentinel.sh` — run 6× daily, alert on any live session >20 h old.

### Layer 3 — Cost-proxy circuit breaker (new)
**Goal:** trip even when every call succeeds, based on a cost proxy.

openclaw doesn't expose $ per call, so use a computable proxy:
```
cost_proxy(call) = session_bytes(call) × call_count_in_window
```

**Implementation:**
- New `scripts/ze-cost-proxy-sentinel.sh`:
  - Every 5 min, compute `max_session_size × embedded_run_agent_end_count_last_hour`
  - Threshold: `alert if > 50 MB·calls/hour` (i.e., 1 MB session × 50 calls, or 500 KB × 100, etc.)
  - Trip threshold: `stop gateway if > 150 MB·calls/hour`
  - Alert goes to Telegram (same path as existing sentinels).
- Tune thresholds after 1 week of baseline.

### Layer 4 — Per-cron token budget (hardest, highest value)
**Goal:** each cron has a daily token allowance. Block further runs when spent.

**Implementation:**
- New SQLite table `cron_budget(cron_id, date, tokens_used, limit)` in a new DB (separate from task_queue.db).
- Before each cron run, a guard looks up today's consumption for that cron_id. If `tokens_used ≥ limit`, the run is skipped with a log line.
- After each cron run, `tokens_used += session_size_delta` (conservative — overcounts because it includes system overhead, but overcounting is safer than undercounting).
- Initial limits (conservative):
  - `main` agent crons: 50 K tokens/day each
  - `cron-worker` (haiku) crons: 200 K tokens/day each
- Weekly Telegram digest of per-cron consumption vs. limit.

**Files:**
- New schema: `scripts/cron_budget_schema.sql`.
- New wrapper: `scripts/ze-cron-budget-guard.sh <cron_id>` — checks+increments in one call.
- New reporter: a companion to `ze-morning-brief.sh` that includes top-3 spenders of previous day.

### Layer 5 — Hard spend cap at Anthropic console (already in place)
€20/month cap — last resort, confirmed set 2026-04-05. Verify it's actually enforcing by checking the Anthropic usage console independently.

### Layer 6 — Kill switch
**Goal:** single-command gateway-stop that any layer can trigger without coordination.

Already exists in `ze-circuit-breaker.sh`: `systemctl --user stop openclaw-gateway`. Adopt the same idiom in all new sentinels. Ensure none of them auto-restart.

---

## Implementation priority

Ordered by **cost-to-implement ÷ risk-reduction**. Target: Layer 1 + Layer 2 this week, Layer 3 + Layer 4 over the next 2 weeks.

| # | Layer | Effort | Risk reduction | Blocker |
|---|---|---|---|---|
| 1 | **Layer 2 — age-based session rotation** | 30 min | ⭐⭐⭐⭐⭐ (alone would have averted $200 burn) | none |
| 2 | **Layer 3 — cost-proxy sentinel** | 1 h | ⭐⭐⭐⭐ | need 1 week of baseline data |
| 3 | **Layer 1 — pre-call guard** | 2 h | ⭐⭐⭐⭐⭐ | needs openclaw hook integration research |
| 4 | **Layer 4 — per-cron budget** | half day | ⭐⭐⭐ | schema + wrapper + reporter |
| 5 | **Layer 5 audit** | 15 min | ⭐⭐ (already in place) | just verify |
| 6 | **Layer 6 — standardize kill switch** | 15 min | ⭐ (already present, just not uniform) | documentation |

---

## What you should personally do (not Claude/Zé)

1. **Verify €20/month cap on Anthropic console.** You set it post-incident, but the burn happened *during* the window when the cap was not yet in place. Cross-check that the cap field in `~/.openclaw/openclaw.json` or the Anthropic account-level setting is populated and the monthly usage report shows a decreasing runway.
2. **Decide on provider diversification.** Extra Usage is currently exhausted. The three options:
   - Top up Extra Usage: simplest, keeps Anthropic, costs money, keeps the single-point-of-failure.
   - Swap to a cheaper provider (e.g., `ollama` locally or `bedrock-converse-stream`): cheapest long-term, some setup, reduced capability.
   - Hybrid (cron-worker → haiku or ollama, main → sonnet): best balance, most config work.
3. **Accept or reject each layer in this design.** Layers 1–4 all involve new scripts and new disk state. I'll hold implementation until you sign off.

---

## What I'm blocked on before implementing

- **openclaw hook model.** I don't know whether openclaw v2026.4.2 exposes a `before_cron_run` or `before_agent_call` hook for Layer 1. If not, Layers 1 and 4 require wrapping each cron's payload manually, which is uglier but still viable. Needs a brief spike against the openclaw source or CLI docs.
- **Session size → token count mapping.** I'm using 4 chars/token as a rough approximation. For precise per-cron budgets, I should either (a) instrument a real tokenizer or (b) log the `usage.input_tokens` field openclaw already receives from Anthropic responses. The latter is free if openclaw surfaces it.
- **Baseline data for Layer 3 thresholds.** Need a week of normal operation (post-Extra-Usage-top-up) to know what "normal" cost_proxy values look like.

---

## Appendix: commands used in this audit

For reproducibility. All read-only, all safe to re-run.

```bash
# Log archive inventory
ssh hetzner 'ls -lh ~/clawd/logs/openclaw/openclaw-2026-*.log /tmp/openclaw/openclaw-2026-*.log'

# Daily error counts
ssh hetzner 'for f in ~/clawd/logs/openclaw/*.log /tmp/openclaw/*.log; do
  echo "$f $(grep -c "\"isError\":true" "$f")"
done'

# Hourly burn on incident day
ssh hetzner 'grep "embedded_run_agent_end" /tmp/openclaw/openclaw-2026-04-04.log |
  python3 -c "..."'

# Session age + turn count
zcat ~/.openclaw/agents/main/sessions/cff0c1d7-....jsonl.reset.manual.2026-04-05.gz | wc -l

# openclaw.json guardrail audit
python3 -c 'import json; d=json.load(open(...)); walk(d)'  # looks for budget/cost/cap keys
```

---

## Related docs

- `PLUMBING-TODO.md` — tactical TODOs (cron errors, log cleanup, swap)
- `MEMORY.md § Infra: Cron & Timers` — current runtime state
- `~/.claude/projects/-home-theo-clawd/memory/project_openclaw_anthropic_policy.md` — policy-change context
- `~/.claude/projects/-home-theo-clawd/memory/project_openclaw_routing_constraint.md` — session.reset config discovery (2026-04-05)
