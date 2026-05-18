# OpenClaw Context Bloat & Credit Burn Diagnosis

> Generated 2026-04-06 from local mirror analysis (~/clawd synced from VPS via Syncthing).
> Companion docs: `TOKEN-BURN-AUDIT.md`, `CRONS.md`, `HEARTBEAT.md`.

---

## Executive Summary

**Three root causes, ranked by severity:**

| # | Root Cause | Severity | Status |
|---|-----------|----------|--------|
| 1 | **Zombie sessions**: 17 live `.jsonl` files, oldest 460h (19 days), zero auto-rotation running locally | CRITICAL | Active bleed on VPS if sentinels aren't firing |
| 2 | **28 crons hitting one shared `main` agent session** with no context truncation — each cron appends to the same session, compounding context size | HIGH | Structural, ongoing |
| 3 | **Morning brief pipeline makes 6 Claude API calls/day** (1 synthesis + 5 intel annotations) via hardcoded OAuth token in `synthesize_brief.py` | MEDIUM | Cost is small (~3K tokens/day), but the hardcoded credential is a security risk |

**Estimated overnight burn rate (normal operation):** ~5K-15K tokens/day from crons alone, ~$0.02-0.07/day at standard pricing. The danger isn't the baseline — it's the **compounding session growth** that pushed the incident session to 1.42M tokens and $8.52/call.

---

## 1. The Bloat Loop: How Sessions Grow Without Bound

### The Mechanism

```
openclaw.json → session.dmScope = "per-channel-peer"
                session.reset   = (MISSING — no auto-reset config)
                session.maxAge  = (MISSING)
                session.maxTokens = (MISSING)
```

Every cron job that targets `sessionTarget=main` **appends to the same session file**. The session file is a JSONL (JSON Lines) format where each API turn adds lines for: user message, assistant response, tool calls, tool results, thinking spans.

**The compounding loop:**
1. Cron fires → sends message to `main` agent
2. OpenClaw loads **entire session JSONL** as conversation history
3. Anthropic API processes full history → responds
4. Response appended to session → session grows
5. Next cron fires → loads the now-larger session
6. Repeat. **Each call is more expensive than the last.**

### Evidence: Current Session State (Local Mirror)

| Age | Size | Est Tokens | File | Risk |
|-----|------|-----------|------|------|
| **460h** (19d) | 880 KB | ~220K | `520f08b2...jsonl` | **LONG-CONTEXT TIER** ($6/M vs $3/M) |
| 420h (17d) | 945 KB | ~236K | `f6126eee...jsonl` | **LONG-CONTEXT TIER** |
| 447h (18d) | 418 KB | ~104K | `5ab3c468...jsonl` | Approaching threshold |
| 32h | 419 KB | ~104K | `52d08c3c...jsonl` | Approaching threshold |
| 13h | 93 KB | ~23K | `c4852e54...jsonl` | OK |

**17 total session files**, combined 3.2 MB. The two largest are already in the long-context premium tier (>200K tokens = 2x price multiplier).

> **Note:** These are synced from VPS. If `ze-session-rotate.sh` is running correctly on the VPS, these may already be rotated there. But the local mirror shows no rotation has occurred for the oldest files, suggesting **either Syncthing lag or the rotation timer isn't firing on VPS.**

### Config Gap: `openclaw.json` Session Block

```json
"session": {
    "dmScope": "per-channel-peer"
    // MISSING: "reset", "maxAge", "maxTokens", "rotateBytes"
    // These fields were lost in the v2026.4.2 upgrade
}
```

**Fix (immediate):** Add session lifecycle config:
```json
"session": {
    "dmScope": "per-channel-peer",
    "maxAge": "24h",
    "maxTokens": 100000,
    "rotateBytes": 409600
}
```
*Caveat: verify these fields exist in openclaw v2026.4.2. TOKEN-BURN-AUDIT.md notes `session.reset.*` config is absent in this version.*

---

## 2. The 28 Cron Jobs: Anatomy of the Load

### Cron Frequency Analysis

| Frequency | Count | Agent | Model | Session Impact |
|-----------|-------|-------|-------|----------------|
| Every 30 min | 1 (mc-sync-agents) | cron-worker | haiku | isolated (safe) |
| Daily (morning cluster 06:20-08:05 BRT) | 8 | mixed | mixed | **6 hit `main` session** |
| Daily (afternoon/evening) | 6 | mixed | mixed | 3 hit `main` session |
| Weekly | 6 | mixed | mixed | 4 hit `main` session |
| Monthly | 3 | cron-worker | haiku | isolated (safe) |

### The Dangerous Cluster: 06:20-08:30 BRT

These fire within ~2 hours every weekday morning:

| Time | Cron | Agent | Target | Tokens/call (est) |
|------|------|-------|--------|-------------------|
| 06:20 | Morning Workout Nudge | main | main | ~500 |
| 06:50 | Morning Brief v2 | cron-worker | isolated | ~3K (6 Claude calls) |
| 07:30 | Morning Health Brief | cron-worker | isolated | ~500 |
| 08:00 | Obsidian Morning Routine | main | **main** | ~2K |
| 08:00 | Heartbeat Freshness Check | cron-worker | isolated | ~500 |
| 08:00 | Health Morning Log | main | **main** | ~1K |
| 08:05 | Daily Note Generator | cron-worker | isolated | ~500 |
| 08:30 | Trading Pre-Market Scan | cron-worker | isolated | ~500 |

**The 3 crons hitting `sessionTarget=main`** (Obsidian Morning Routine, Health Morning Log, Morning Workout Nudge) all **append to the same growing session**. Each successive call carries the accumulated context from prior calls.

### Key Split: `main` vs `cron-worker`

The `cron-worker` agent (haiku, `sessionTarget=isolated`) was created 2026-04-05 specifically for cost control. It's well-designed — each cron gets an ephemeral session.

**But 13 crons still use `main` (sonnet, `sessionTarget=main`):**
- Obsidian Morning Routine
- Obsidian Git Backup
- End-of-Day Review
- Sunday Mini-Review
- Obsidian Vault Maintenance
- Weekly Digest Email
- Health Morning Log
- Weekly Kickoff
- Friday Weekly Review
- Weekly Life Admin
- Morning Workout Nudge
- Bedtime Reminder
- Appel Parents

**Each of these grows the shared `main` session.** Over a full week without rotation, the `main` session accumulates context from ~35+ cron invocations (plus any Telegram conversations), easily hitting 500KB-1MB.

---

## 3. The Morning Brief Pipeline: 6 Claude API Calls/Day

### Call Breakdown

| Step | Script | Model | Tokens (est) | Notes |
|------|--------|-------|-------------|-------|
| Intel annotation ×5 | `fetch_intel.py:348-374` | haiku (via API key) | 250/call × 5 = 1,250 | Sequential loop, no parallelism |
| Brief synthesis ×1 | `synthesize_brief.py:69-91` | sonnet (via `claude --print`) | ~1,500 | Full JSON data dump, no truncation |
| **Total** | | | **~2,750/day** | **~$0.01/day** — negligible cost |

### Security Issue: Hardcoded OAuth Token

`synthesize_brief.py:17`:
```python
CLAUDE_TOKEN = "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"
```

This is a **Claude Code OAuth token hardcoded in source**. If this repo is ever public or the token is scraped, it grants API access under your account. It should be loaded from `~/clawd/credentials/` (which `fetch_intel.py` already does correctly via `_load_api_key()`).

### Inefficiency: No Data Truncation Before Synthesis

`morning-brief-v2.py:128` passes the **full JSON dump** of all module data to Claude. If calendar returns 50 events or intel returns large abstracts, this inflates the synthesis prompt unnecessarily. The synthesis prompt template already specifies "top 3-5 tasks" and "up to 5 intel items", so the data should be pre-trimmed.

---

## 4. Sentinel Gap Analysis

### What's Deployed

| Sentinel | Frequency | Catches | Blind Spot |
|----------|-----------|---------|------------|
| ze-circuit-breaker | 2 min | Error bursts (3+ in 10 min) | Silent expensive successful calls |
| ze-burn-sentinel | 1 hour | High turn count (>500/day) | Low-frequency but large-context calls (the exact incident pattern) |
| ze-session-sentinel | 2x/day | Sessions >1.5 MB | Sessions at 200-1500 KB already in long-context tier |
| ze-session-rotate | Daily 04:00 UTC | Size >2 MB, age >24h | 23h59m of growth before daily fire; **only runs on VPS** |
| ze-precall-guard | Before dispatch | Sessions >400 KB | **Only called by task-dispatch.sh** — crons bypass it entirely |
| ze-cost-proxy-sentinel | 5 min | KB×turns product | Good coverage, but thresholds need tuning |
| ze-cron-budget-guard | Before cron | Per-cron daily token budget | **Not wired into all 28 crons yet** |

### Critical Gap: Precall Guard Not Wired to Crons

`ze-precall-guard.sh` is the **best defense** against context bloat (checks session size before each API call, force-rotates if >400KB). But it's only called from `task-dispatch.sh`. The 28 crons in `~/.openclaw/cron/jobs.json` fire directly through the gateway with no precall check.

**This means:** The 13 crons targeting `main` can accumulate the session past 400KB → 1MB → 2MB → long-context tier without the precall guard ever intervening.

### Critical Gap: Session Sentinel Warn Threshold Too Late

`ze-session-sentinel.sh` warns at 1.5 MB (1,536 KB ≈ ~384K tokens). But the long-context pricing tier kicks in at **200K tokens ≈ ~800 KB**. By the time the sentinel warns, you've been paying 2x for every call since the session crossed 800 KB.

**Fix:** Lower `WARN_BYTES` to 800 KB (200K token boundary) and add a second threshold at 400 KB (precall guard equivalent).

---

## 5. Overnight Token Estimate (Last 24h)

### From Gateway Logs

The most recent persisted gateway log is `openclaw-2026-04-04.log` (70 KB). Today's log (`/tmp/openclaw/openclaw-2026-04-06.log`) is **empty on the local machine** — expected, since the gateway runs on VPS.

From the Apr 4 log:
- `embedded_run_agent_end` events: 1 (in persisted portion)
- Rate limit errors: 0 (in persisted portion)
- The bulk of Apr 4 errors (2,729 total per TOKEN-BURN-AUDIT.md) were in the live `/tmp/openclaw/` log on VPS

**Cannot accurately estimate last-24h token burn from local mirror.** The live log lives at `/tmp/openclaw/openclaw-$(date -u +%Y-%m-%d).log` on the VPS only. To get real numbers:
```bash
ssh hetzner 'grep -c "embedded_run_agent_end" /tmp/openclaw/openclaw-2026-04-06.log'
ssh hetzner 'wc -c ~/.openclaw/agents/main/sessions/*.jsonl'
```

### Estimated Daily Cost (Steady State)

| Source | Calls/day | Avg tokens/call | Daily tokens | Daily cost |
|--------|-----------|-----------------|-------------|------------|
| 13 `main` crons (weekday) | ~8 | 5K-50K (grows with session) | 40K-400K | $0.12-$2.40 |
| Morning brief pipeline | 6 | 500 | 3K | $0.01 |
| Telegram conversations | 0-10 | 5K-50K | 0-500K | $0-$3.00 |
| Task dispatches | 0-3 | 1K | 0-3K | <$0.01 |
| **Total baseline (quiet day)** | | | **~50K** | **~$0.15** |
| **Total peak (active + bloated session)** | | | **~1M** | **~$6.00** |

The **session size is the dominant cost variable**, not the number of calls. A 50K-token session costs $0.15/call; a 500K-token session costs $3.00/call (long-context tier).

---

## 6. Fixes — Priority Order

### P0: Stop the Bleed (Do Today)

#### Fix 1: Verify session rotation is running on VPS
```bash
ssh hetzner 'systemctl --user list-timers ze-session-rotate*'
ssh hetzner 'tail -5 ~/clawd/logs/ze-session-rotate.log'
ssh hetzner 'ls -lhS ~/.openclaw/agents/main/sessions/*.jsonl | head -5'
```
If rotation isn't firing, manually rotate now:
```bash
ssh hetzner 'for f in ~/.openclaw/agents/main/sessions/*.jsonl; do
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  [ "$sz" -gt 102400 ] && mv "$f" "${f}.reset.manual.$(date -u +%Y-%m-%d)"
done'
```

#### Fix 2: Lower session sentinel threshold
In `ze-session-sentinel.sh:10`:
```bash
# BEFORE:
WARN_BYTES=$((1536 * 1024))      # 1.5 MB
# AFTER:
WARN_BYTES=$((400 * 1024))       # 400 KB (~100K tokens, below long-context tier)
```

#### Fix 3: Move hardcoded token out of `synthesize_brief.py`
In `synthesize_brief.py:17`, replace the hardcoded token with:
```python
CLAUDE_TOKEN = os.environ.get("CLAUDE_CODE_OAUTH_TOKEN", "")
if not CLAUDE_TOKEN:
    cred_path = Path.home() / "clawd" / "credentials" / "claude-code.env"
    if cred_path.exists():
        for line in cred_path.read_text().splitlines():
            if "CLAUDE_CODE_OAUTH_TOKEN=" in line:
                CLAUDE_TOKEN = line.split("=", 1)[1].strip().strip('"')
                break
```
Then rotate the exposed token.

### P1: Structural Fixes (This Week)

#### Fix 4: Wire precall guard into ALL crons
Every cron payload targeting `main` should prepend:
```bash
bash ~/clawd/scripts/ze-precall-guard.sh main || exit 1
```
This prevents any cron from running against a session >400KB.

**Implementation:** Edit each cron's payload in `~/.openclaw/cron/jobs.json` to chain the guard, or create a wrapper script that all crons route through.

#### Fix 5: Migrate remaining `main` crons to `cron-worker`
These 13 crons don't need Sonnet or the shared Telegram session:
- Morning Workout Nudge, Bedtime Reminder, Appel Parents → haiku + isolated
- Health Morning Log → haiku + isolated
- Obsidian Git Backup, Daily Note Generator → already simple scripts, move to cron-worker

**Keep on `main` only:** crons that genuinely need the Telegram conversation context (End-of-Day Review, Weekly Kickoff, Weekly Digest Email).

#### Fix 6: Add `session.maxAge` to openclaw.json (if supported)
```json
"session": {
    "dmScope": "per-channel-peer",
    "maxAge": "24h"
}
```
Test on VPS first. If openclaw ignores the field, the external `ze-session-rotate.sh` is the fallback.

### P2: Optimization (Next 2 Weeks)

#### Fix 7: Pre-trim morning brief data before synthesis
In `morning-brief-v2.py`, before passing to `synthesize()`:
```python
if "calendar" in data and "events" in data["calendar"]:
    data["calendar"]["events"] = data["calendar"]["events"][:15]
if "tasks" in data and "tasks" in data["tasks"]:
    data["tasks"]["tasks"] = data["tasks"]["tasks"][:5]
if "intel" in data and "items" in data["intel"]:
    data["intel"]["items"] = data["intel"]["items"][:5]
    for item in data["intel"]["items"]:
        item.pop("body", None)  # annotation replaces body
```

#### Fix 8: Parallelize intel annotations
In `fetch_intel.py:407-423`, replace the sequential loop with `ThreadPoolExecutor(max_workers=3)`.

#### Fix 9: Wire cron-budget-guard into all crons
Each cron checks budget before running and records usage after:
```bash
bash ~/clawd/scripts/ze-cron-budget-guard.sh check "$CRON_ID" || exit 0
# ... actual cron work ...
bash ~/clawd/scripts/ze-cron-budget-guard.sh record "$CRON_ID" "$TOKENS_USED"
```

---

## 7. Architecture Diagram: Where Tokens Burn

```
                         Telegram
                            │
                            ▼
                    ┌───────────────┐
                    │   OpenClaw    │
                    │   Gateway     │
                    │  (VPS:18789)  │
                    └───────┬───────┘
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
         ┌──────────┐ ┌──────────┐ ┌──────────┐
         │  main    │ │cron-     │ │prompt-    │
         │  agent   │ │worker    │ │master     │
         │(sonnet)  │ │(haiku)   │ │(haiku)    │
         └────┬─────┘ └────┬─────┘ └──────────┘
              │            │
    ┌─────────┤            │
    │         │            │
    ▼         ▼            ▼
  SHARED    13 crons    15 crons
  session   (append!)   (isolated ✓)
  .jsonl    ─────────
  ────────  │ Obsidian Morning Routine
  GROWS     │ End-of-Day Review
  WITH      │ Health Morning Log
  EVERY     │ Morning Workout Nudge
  CALL      │ Bedtime Reminder
            │ ... (8 more)
            │
            ▼
    Session bloats → long-context tier → $$$
```

---

## 8. Key Config Files & Code Paths

| File | Line | Issue |
|------|------|-------|
| `~/.openclaw/openclaw.json:63-65` | `session` block | Missing `maxAge`, `maxTokens`, `reset` |
| `~/.openclaw/openclaw.json:43-46` | `agents.defaults.compaction` | `reserveTokensFloor: 20000` is not a cost cap |
| `scripts/brief-modules/synthesize_brief.py:17` | `CLAUDE_TOKEN` | Hardcoded OAuth token |
| `scripts/brief-modules/synthesize_brief.py:64-66` | `build_prompt()` | No data truncation before synthesis |
| `scripts/brief-modules/fetch_intel.py:407-423` | `annotate_top()` | Sequential Claude calls (should be parallel) |
| `scripts/ze-session-sentinel.sh:10` | `WARN_BYTES` | 1.5MB threshold too late (should be 400KB) |
| `scripts/ze-precall-guard.sh` | (whole file) | Only called from task-dispatch.sh, not from crons |
| `CRONS.md` rows 2,6,8,15,17,18,19,25,26,27,28 | `main` agent | 13 crons growing shared session |

---

## 9. Verification Commands (Run on VPS)

```bash
# 1. Current session health
ssh hetzner 'for f in ~/.openclaw/agents/*/sessions/*.jsonl; do
  [ -f "$f" ] || continue; case "$f" in *.reset.*) continue ;; esac
  age=$((( $(date +%s) - $(stat -c %Y "$f") ) / 3600))
  echo "${age}h | $(( $(stat -c%s "$f") / 1024 ))KB | $f"
done | sort -rn'

# 2. Are sentinels firing?
ssh hetzner 'systemctl --user list-timers --all | grep ze-'

# 3. Today's turn count
ssh hetzner 'grep -c "embedded_run_agent_end" /tmp/openclaw/openclaw-$(date -u +%Y-%m-%d).log 2>/dev/null || echo 0'

# 4. Estimated daily spend
ssh hetzner 'max_kb=$(for f in ~/.openclaw/agents/*/sessions/*.jsonl; do stat -c%s "$f" 2>/dev/null; done | sort -rn | head -1)
turns=$(grep -c "embedded_run_agent_end" /tmp/openclaw/openclaw-$(date -u +%Y-%m-%d).log 2>/dev/null || echo 0)
echo "max_session=$((max_kb/1024))KB turns=$turns est_cost_per_call=\$$(python3 -c "print(f\"{$max_kb/1024*250*4.5/1e6:.3f}\")")"'
```

---

## TL;DR

1. **Sessions grow without bound** because `openclaw.json` has no `session.reset`/`maxAge`/`maxTokens`. 13 crons append to the shared `main` session daily.
2. **The precall guard (400KB ceiling) only protects task dispatches**, not the 28 crons — the main attack surface.
3. **The session sentinel warns at 1.5MB** but the long-context price jump happens at ~800KB (200K tokens).
4. **Fix priority:** Rotate stale sessions now > wire precall guard into crons > migrate `main` crons to `cron-worker` > lower sentinel threshold.
5. **Security:** Rotate the hardcoded OAuth token in `synthesize_brief.py`.
