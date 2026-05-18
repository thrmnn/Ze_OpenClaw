# OpenClaw File Loading Architecture

> How OpenClaw loads workspace files into agent sessions.
> Source: reverse-engineered from `openclaw/dist/agent-scope-*.js` (v2026.3.13) + `openclaw.json` config.
> Written: 2026-04-08.

---

## The 8 Convention Files

OpenClaw hardcodes these 8 filenames in `agent-scope`:

```js
const DEFAULT_AGENTS_FILENAME    = "AGENTS.md";
const DEFAULT_SOUL_FILENAME      = "SOUL.md";
const DEFAULT_TOOLS_FILENAME     = "TOOLS.md";
const DEFAULT_IDENTITY_FILENAME  = "IDENTITY.md";
const DEFAULT_USER_FILENAME      = "USER.md";
const DEFAULT_HEARTBEAT_FILENAME = "HEARTBEAT.md";
const DEFAULT_BOOTSTRAP_FILENAME = "BOOTSTRAP.md";
const DEFAULT_MEMORY_FILENAME    = "MEMORY.md";
```

If these files exist in the workspace root (`agents.defaults.workspace` in `openclaw.json` = `~/clawd`), OpenClaw loads them into every agent session as system context.

**CLAUDE.md** is loaded separately — it's handled by the `boot-md` internal hook (shared with Claude Code), not by OpenClaw's agent-scope module.

## Loading Order

```
Session start
  |
  ├── boot-md hook           → loads CLAUDE.md (workspace system prompt)
  ├── bootstrap-extra-files  → loads the 8 convention files above
  ├── session-memory hook    → loads session history from .jsonl
  └── command-logger hook    → logs commands
```

All 4 hooks are enabled in `openclaw.json > hooks.internal.entries`.

## Which Files We Have (and Must Keep)

| File | Status | Purpose | Deletable? |
|------|--------|---------|------------|
| `CLAUDE.md` | EXISTS | System prompt — identity, commands, standing rules | **NO** — primary system prompt |
| `AGENTS.md` | EXISTS | Memory system, MC reporting, safety guardrails | **NO** — loaded by convention |
| `SOUL.md` | EXISTS | Philosophical rules, tone, boundaries | **NO** — loaded by convention |
| `IDENTITY.md` | EXISTS | Zé's name, traits, vibe | **NO** — loaded by convention |
| `USER.md` | EXISTS | Théo's info, language prefs | **NO** — loaded by convention |
| `TOOLS.md` | EXISTS | Tool quick-reference, connected services | **NO** — loaded by convention |
| `MEMORY.md` | EXISTS | Hot context — projects, infra, rules | **NO** — loaded by convention |
| `HEARTBEAT.md` | EXISTS | Monitoring rotation schedule | **NO** — loaded by convention |
| `BOOTSTRAP.md` | ABSENT | First-run bootstrap (deleted after first run per AGENTS.md) | N/A — only needed on first run |

**Rule: Never delete any of these 9 files.** They are all injected into every session.

## Config: openclaw.json

Key sections (from `~/.openclaw/openclaw.json`):

```json
{
  "agents": {
    "defaults": {
      "model": { "primary": "anthropic/claude-sonnet-4-6" },
      "workspace": "/home/theo/clawd",         // <-- where convention files are read from
      "compaction": {
        "reserveTokensFloor": 20000,
        "memoryFlush": { "enabled": true, "softThresholdTokens": 4000 }
      }
    },
    "list": [
      { "id": "main" },
      { "id": "prompt-master-fast", "workspace": "/home/theo/prompt_master", ... }
    ]
  },
  "session": {
    "dmScope": "per-channel-peer"
    // MISSING: reset, maxAge, maxTokens, rotateBytes
  },
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "boot-md":                 { "enabled": true },   // loads CLAUDE.md
        "bootstrap-extra-files":   { "enabled": true },   // loads the 8 convention files
        "command-logger":          { "enabled": true },
        "session-memory":          { "enabled": true }
      }
    }
  },
  "memory": {
    "backend": "qmd",
    ...
  }
}
```

## Two-Agent Architecture

| Agent | Model | Session Scope | Convention Files Source |
|-------|-------|---------------|----------------------|
| `main` | claude-sonnet-4-6 | `per-channel-peer` (shared, grows) | `~/clawd/` (default workspace) |
| `cron-worker` | claude-haiku-4-5 | `isolated` (ephemeral per-cron) | `~/clawd/` (inherits default) |
| `prompt-master-fast` | claude-haiku-4-5 | isolated | `/home/theo/prompt_master/` (own workspace) |

Both `main` and `cron-worker` load the same 9 files from `~/clawd/`.
`prompt-master-fast` loads its own set from `/home/theo/prompt_master/`.

## Session Scoping

- **sessionTarget=main**: Reuses `~/.openclaw/agents/main/sessions/{channel-id}.jsonl` — session grows with every cron/DM interaction
- **sessionTarget=isolated**: Creates ephemeral session file per invocation — discarded after completion
- **per-channel-peer**: "channel" = Telegram DM with Théo, "peer" = agent identity

## Cost Implications

Every session start pays the token cost of all 9 injected files:
- CLAUDE.md (~100 lines) + AGENTS.md (~86 lines) + SOUL.md (~38 lines) + IDENTITY.md (~20 lines) + USER.md (~28 lines) + TOOLS.md (~43 lines) + MEMORY.md (~124 lines) + HEARTBEAT.md (~99 lines)
- Total: ~550 lines, ~2500 tokens per session start
- At $3/M input tokens = ~$0.0075 per session

The danger is not the convention files — it's the **session history** that grows unbounded when `session.maxAge` is not configured.

## Editing Rules

1. **Keep all 9 files lean.** Every token is paid on every API call for the `main` agent's shared session.
2. **MEMORY.md has a 5000-char target.** It's the most frequently updated; enforce the limit.
3. **Move reference content to docs/.** Convention files should contain only what the agent needs *every session*, not comprehensive documentation.
4. **Content overlap between files is expected.** CLAUDE.md is the authoritative system prompt; SOUL.md/IDENTITY.md/USER.md provide personality/context layers. They serve different roles even when content overlaps.

## Related Docs

- `PLUMBING-TODO.md` — session lifecycle gaps
- `docs/token-burn-audit.md` — $200 incident forensics
- `docs/openclaw-diagnosis.md` — context bloat analysis
- `docs/gateway-architecture.md` — gateway design
