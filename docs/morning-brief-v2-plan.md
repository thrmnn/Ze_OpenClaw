# Morning Brief v2 — Deep Design Plan

> Authored: 2026-03-23 | Status: Pre-implementation

---

## 1. What This Brief Is For

Théo is an early-career robotics/AI engineer (perception, navigation, MLOps) working simultaneously on:
- Academic research (LAI paper, Brisa+)
- Job hunt (robotics/autonomy roles)
- AI agency build
- Personal development (health, trading)

The brief must do one thing above all: **reduce cognitive startup cost each morning**. Not a newsletter — a mission briefing. Scan in 90 seconds, know what matters, start working.

---

## 2. Brief Structure (Final Format)

```
☀️ [Day], [Date]

━━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Calendar
  • [Time] — [Event]
  • [Time] — [Event]
  (empty if none)

📬 Inbox: [N unread] · [N flagged]
  → [Sender]: [subject snippet if urgent]

━━━ FOCUS ━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Top 3 tasks (from Mission Control)
  1. [Task — project tag]
  2. [Task — project tag]  
  3. [Task — project tag]

📄 Papers
  → LAI: [status in 1 line]
  → Brisa+: [next deliverable]

━━━ JOBS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Pipeline: [N active apps] · [N to_apply]
🔭 Radar: [N new hits ≥70 overnight] or "nothing new"
  → [Company — Role — Score] if any

━━━ INTEL ━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 AI/Robotics (3 items, ranked by relevance to Théo)
  1. [Headline] — [source] — [why it matters to you]
  2. [Headline] — [source] — [why it matters to you]
  3. [Headline] — [source] — [why it matters to you]

📡 From the field (X/Twitter voices — if any signal)
  → [Handle]: [key point]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━```

Total length target: **300–400 words**. Scannable, no fluff.

---

## 3. Intel Layer — AI & Robotics Brief (Core Innovation)

This is the section that doesn't exist yet and is the highest-value addition.

### 3.1 Sources

**Tier 1 — High signal (daily)**
| Source | What | Method |
|--------|------|--------|
| arXiv cs.RO + cs.LG | New papers in robotics + ML | RSS `arxiv.org/rss/cs.RO`, `cs.LG` |
| Hugging Face Papers | Top-liked papers daily | RSS `huggingface.co/papers.rss` |
| X voices (Nitter RSS) | Real-time practitioner takes | Existing `fetch-x-voices.py` (fix instances) |
| IEEE Spectrum Robotics | Industry news | RSS feed |

**Tier 2 — Medium signal (scan daily, surface only if notable)**
| Source | What | Method |
|--------|------|--------|
| Hacker News | Tech/AI trending | RSS `hnrss.org/best` filtered |
| MIT News — CSAIL/robotics | Academic announcements | RSS |
| The Batch (DeepLearning.AI) | Weekly digest | RSS |
| Import AI (Jack Clark) | Safety + frontier | RSS / Substack |

**Tier 3 — On-demand only**
- Reddit r/MachineLearning, r/robotics — too noisy for daily
- Arxiv Sanity — search on demand

### 3.2 Relevance Filtering (Critical)

Raw RSS = noise. Every item must pass a relevance score before appearing.

**Théo's interest profile (hardcoded):**
```python
INTEREST_PROFILE = {
    "core": [
        "embodied AI", "robot learning", "manipulation", "locomotion",
        "perception", "SLAM", "autonomous navigation", "sim-to-real",
        "foundation models for robotics", "diffusion policy", "RL robotics"
    ],
    "secondary": [
        "computer vision", "3D scene understanding", "MLOps",
        "edge deployment", "Jetson", "transformer architectures",
        "multi-modal models", "autonomous vehicles"
    ],
    "job_relevant": [
        "Apptronik", "Boston Dynamics", "Figure AI", "Waymo",
        "Agility Robotics", "1X", "NVIDIA Isaac", "Tesla Optimus"
    ],
    "filter_out": [
        "crypto", "blockchain", "finance ML", "NLP-only", "social media AI"
    ]
}
```

**Scoring pipeline:**
1. Fetch all items from all RSS sources
2. For each item: LLM call (haiku/sonnet-mini) → score 0-10 vs interest profile
3. Keep top 5 items ≥7/10
4. For each kept item: generate 1-line "why it matters to Théo" annotation
5. Fallback: if < 3 items ≥7, lower threshold to 5

### 3.3 X Voices — Expanded List

Current list is too small (4 accounts). Expand to ~20:

```json
{
  "voices": {
    "robotics": [
      "karpathy",           // Andrej Karpathy — top signal
      "chelsea_finn",       // Chelsea Finn — robot learning
      "svlevine",           // Sergey Levine — RL/robotics
      "pieter_abbeel",      // Pieter Abbeel — robot learning
      "hausman_karol",      // Karol Hausman — Google robotics
      "nvidiarobotics",     // NVIDIA Robotics
      "figure_robot",       // Figure AI
      "boston_dynamics",    // Boston Dynamics
      "lerobothf",          // LeRobot / HuggingFace robotics
      "agilex_robotics"     // AgileX / mobile manipulation
    ],
    "ai_research": [
      "ylecun",             // Yann LeCun
      "fchollet",           // François Chollet
      "drfeifei",           // Fei-Fei Li
      "hardmaru",           // David Ha — generative models
      "jeremyphoward",      // Jeremy Howard — practical ML
      "alex_kendall"        // Alex Kendall — perception/autonomy
    ],
    "industry_and_commentary": [
      "emollick",           // Ethan Mollick — applied AI
      "sama",               // Sam Altman
      "demishassabis",      // Demis Hassabis
      "nautilus28"          // Nathan Lambert — RLHF/robotics
    ]
  }
}
```

### 3.4 Nitter Reliability Fix

Current Nitter instances are mostly dead. Strategy:
1. Use `nitter.poast.org`, `nitter.privacydev.net`, `nitter.cz` with 5s timeout
2. If all fail: skip X section gracefully (don't error, just omit)
3. Add `status: "X unavailable today"` line if all instances fail
4. Long-term: consider Twitter API v2 free tier (500 reads/month) as backup

---

## 4. Multi-Agent Architecture

```
[Cron: 6:50am Brazil, weekdays]
        ↓
[Orchestrator Agent]
  spawns 5 parallel agents:
  ├── Agent A: DataFetcher-Calendar   (~5s)
  ├── Agent B: DataFetcher-Email      (~8s)
  ├── Agent C: DataFetcher-Jobs       (~5s)
  ├── Agent D: DataFetcher-Intel      (~25s) ← slowest, RSS + scoring
  └── Agent E: DataFetcher-Tasks      (~3s)
        ↓ (wait all, timeout 45s)
[Synthesizer Agent]
  - Receives all data as structured JSON
  - Calls Claude claude-haiku-4-5 (fast + cheap)
  - Prompt: format brief per template, annotate intel items
  - Output: final brief string
        ↓
[Sender]
  - Sends via Telegram (OpenClaw routing, not curl)
  - Logs to memory/briefs/YYYY-MM-DD.md
  - Updates heartbeat-state.json
```

### Why subagents for data fetching?
- Calendar API: 5s
- Gmail API: 8s
- RSS fetch (10 feeds): 15-25s
- Serial = 35-45s minimum
- Parallel = ~25s wall time

### Cost estimate
- 5 data agents × ~500 tokens each = 2,500 tokens
- 1 synthesizer × ~2,000 tokens = 2,000 tokens
- Intel scoring: 3 items × ~200 tokens = 600 tokens
- **Total: ~5,100 tokens/day ≈ $0.005/brief** (negligible)

---

## 5. Files to Build

```
scripts/
  morning-brief-v2.py          ← orchestrator (replaces morning-brief.sh)
  brief-modules/
    fetch_calendar.py           ← Google Calendar, next 24h events
    fetch_email.py              ← Gmail unread count + flagged senders
    fetch_jobs.py               ← tracker.db + radar results
    fetch_tasks.py              ← Mission Control API top tasks
    fetch_intel.py              ← RSS fetch + LLM relevance scoring
    synthesize_brief.py         ← Claude call → formatted string
    send_brief.py               ← Telegram send + logging

data/
  ai-voices.json                ← expand to 20 voices (update existing)
  rss-sources.json              ← new: RSS source registry
  interest-profile.json         ← new: Théo's relevance filter profile
  quotes.json                   ← expand from 10 → 50 quotes

memory/briefs/
  YYYY-MM-DD.md                 ← daily brief archive
```

---

## 6. Cron Consolidation Plan

**Current fragmented crons (7-8am):**
- Morning Health Brief → ❌ replace with v2
- Health Morning Log → ✅ keep (health tracking, separate concern)
- Obsidian Morning Routine → merge into v2 (daily note creation)
- Daily Note Generator → merge into v2
- Heartbeat Freshness Check → keep (separate system concern)

**After consolidation:**
- `06:50` → Morning Brief v2 (main brief + daily note creation)
- `08:00` → Health Morning Log (keep separate)
- `06:30` → Pre-Workout Meal Reminder (keep)
- `08:30` → Trading Pre-Market Scan (keep)

---

## 7. Testing Plan

### Unit tests (before cron activation)
```bash
python3 scripts/brief-modules/fetch_calendar.py --test
python3 scripts/brief-modules/fetch_email.py --test  
python3 scripts/brief-modules/fetch_jobs.py --test
python3 scripts/brief-modules/fetch_intel.py --test
python3 scripts/brief-modules/synthesize_brief.py --test
```

Each module prints its JSON output. Pass/fail per module.

### Integration test
```bash
python3 scripts/morning-brief-v2.py --dry-run
```
Runs full pipeline, outputs to stdout instead of Telegram. Verify:
- [ ] All 5 modules return data within 30s
- [ ] Intel section has 3 items, all with relevance annotation
- [ ] Brief is 250-350 words
- [ ] Format matches template

### Live test
```bash
python3 scripts/morning-brief-v2.py --send-now
```
Triggers full pipeline + sends to Telegram immediately. Verify arrives correctly.

### Cron activation
Only after live test passes. Update OpenClaw cron to point to `morning-brief-v2.py`.

---

## 8. Phase Rollout

| Phase | What | ETA |
|-------|------|-----|
| P1 | Core modules (calendar, email, jobs, tasks) + basic synthesizer | 1 session |
| P2 | Intel module (RSS + scoring) + expanded voices | 1 session |
| P3 | Testing + dry-run validation | 30min |
| P4 | Live test + cron activation | 15min |
| P5 | Cron consolidation (remove fragmented ones) | 15min |

---

## 9. Open Questions (for Théo)

1. **Intel depth:** 5 items ✅
2. **X voices:** Karpathy-tier list ✅ (20 accounts)
3. **arXiv papers:** 1-line abstract summary ✅
4. **Weather:** Dropped ✅
5. **Quotes:** Dropped ✅
6. **Evening brief:** Scope for later — same architecture, different data (reflection + tomorrow prep)
