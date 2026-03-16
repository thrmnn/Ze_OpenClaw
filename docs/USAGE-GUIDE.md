# USAGE-GUIDE.md - Best Practices

## Token-Efficient Memory Access with QMD + Mission Control

### The Problem
Loading entire memory files (MEMORY.md, daily logs) burns 5,000-10,000 tokens per session. Over time, this adds up fast.

### The Solution
Use QMD (Quick Markdown Search) to search memory semantically and retrieve only relevant snippets.

**Token Savings:**
- **Before:** Load entire MEMORY.md (~5,000 tokens)
- **After:** Search + retrieve 3 snippets (~300 tokens)
- **Reduction:** 75-90% fewer tokens per memory query

---

## Pattern: Search Before Spawning Agents

**OLD WAY (token-heavy):**
```bash
# Load entire memory file
cat ~/clawd/MEMORY.md  # 5,000+ tokens

# Spawn agent with full context
# Agent reads everything again → double token burn
```

**NEW WAY (token-efficient):**
```bash
# Search for relevant context first
bash ~/clawd/scripts/mc-memory-search.sh "CERN application status" query

# Output (top 3 results):
# memory/2026-02-24.md: "Started CERN application, need to follow up..."
# memory/2026-02-20.md: "Discussed CERN research interests..."
# MEMORY.md: "CERN - Strong interest in particle physics..."

# Now spawn agent with ONLY relevant snippets (300 tokens vs 5,000)
```

**Benefits:**
- 75-90% token reduction
- Faster searches (indexed)
- Search ALL memory files (not just MEMORY.md)
- Activity tracked in Mission Control

---

## Daily Workflow Integration

### Morning Heartbeat (9-11 AM)
```bash
# Check recent tasks and decisions
mc-memory-search.sh "pending tasks from yesterday" query
mc-memory-search.sh "recent decisions" vsearch

# Log findings to Mission Control automatically
```

### Before Spawning Agents
```bash
# Search for relevant context
mc-memory-search.sh "<topic related to task>" query

# Pass top 3 results to agent as context
# Saves 75-90% tokens vs loading full files
```

### Afternoon Check (2-5 PM)
```bash
# Search for TODOs and follow-ups
mc-memory-search.sh "TODO OR follow-up OR waiting" search

# Results logged to Mission Control dashboard
```

---

## Search Modes Explained

### 1. `query` (Hybrid + Reranking) - BEST QUALITY
```bash
mc-memory-search.sh "CERN application" query
```
- Combines keyword + semantic search
- Re-ranks results for best relevance
- Use for: Important queries, spawning agents

### 2. `vsearch` (Semantic Only) - MEANING-BASED
```bash
mc-memory-search.sh "pending work" vsearch
```
- Understands meaning, not just keywords
- Use for: Conceptual searches, finding related ideas

### 3. `search` (Keyword Only) - FAST
```bash
mc-memory-search.sh "email decisions" search
```
- Simple keyword matching
- Use for: Quick lookups, known terms

---

## Mission Control Integration

Every search is automatically logged to Mission Control:
- **Activity Type:** `memory_search`
- **Message:** `QMD query: '<query>' → 3 results`
- **Agent ID:** `qmd-integration`

View logs at: https://mission-control-ruby-zeta.vercel.app/

**Why log searches?**
- Track what context you're using
- Identify frequent queries (optimize memory structure)
- Debug context issues ("What did I search for before spawning X?")

---

## Token Math Example

**Scenario:** Spawning agent to work on CERN application

**OLD WAY:**
```
Load MEMORY.md: 5,000 tokens
Load 2026-02-24.md: 3,000 tokens
Load 2026-02-23.md: 2,500 tokens
Total: 10,500 tokens
```

**NEW WAY:**
```
mc-memory-search.sh "CERN application" query: 300 tokens
(3 snippets × ~100 tokens each)
Total: 300 tokens
```

**Savings:** 10,200 tokens = 97% reduction!

---

## Quick Reference

```bash
# Search memory with Mission Control logging
~/clawd/scripts/mc-memory-search.sh "<query>" [mode]

# Modes:
# - query  (default) → Hybrid + rerank (best quality)
# - vsearch → Semantic only (meaning-based)
# - search  → Keyword only (fast)

# Examples:
mc-memory-search.sh "pending tasks" query
mc-memory-search.sh "recent decisions" vsearch
mc-memory-search.sh "TODO email" search
```

---

## Next Steps

1. Use QMD search in heartbeats (1x daily)
2. Search before spawning agents (every time)
3. Review Mission Control logs weekly
4. Update memory structure based on search patterns

**Goal:** Never load full memory files again. Search first, retrieve only what's needed.
