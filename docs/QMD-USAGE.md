# QMD - Token-Optimized Memory Search

## Overview

**QMD (Quick Markdown Search)** is a local search engine for markdown files that dramatically reduces token usage by enabling precise, targeted retrieval instead of loading entire memory files into context.

**Key Benefits for Token Optimization:**
- **Semantic search** - Find relevant context by meaning, not just keywords
- **Snippet extraction** - Return only the relevant portions of documents
- **Hybrid ranking** - Combines BM25 + vector search + LLM re-ranking for precision
- **All local** - No API calls, runs on-device with GGUF models

**Token Savings Example:**
- **Before:** Load entire MEMORY.md (5000+ tokens) to answer "what did we decide about email?"
- **After:** `qmd query "email decision" -n 3` returns 3 relevant snippets (~300 tokens)
- **Savings:** ~94% reduction in context tokens

---

## Installation

```bash
# Install bun (if not already installed)
curl -fsSL https://bun.sh/install | bash

# Add bun to PATH
export PATH="$HOME/.bun/bin:$PATH"

# Install qmd globally
bun install -g https://github.com/tobi/qmd
```

---

## Setup (Already Configured)

Collections are indexed directories of markdown files:

```bash
# Memory logs collection
qmd collection add memory --name memory --mask "**/*.md"
qmd context add qmd://memory "Daily memory logs and historical context"

# Workspace config files
qmd collection add . --name workspace --mask "*.md"
qmd context add qmd://workspace "Clawdbot workspace configuration files (SOUL.md, USER.md, AGENTS.md, TOOLS.md, etc.)"

# Generate embeddings (do this after adding collections)
qmd embed
```

**Status:** ✅ Configured (collections: `memory`, `workspace`)

---

## Usage Patterns

### 1. Memory Recall (Replaces memory_search)

**Old way (memory_search):**
```
memory_search("email decisions") → returns snippets from MEMORY.md
```

**New way (qmd):**
```bash
qmd query "email decisions" -n 5 --min-score 0.3
```

**Advantages:**
- Searches ALL memory files (not just MEMORY.md)
- Hybrid search (keyword + semantic + re-ranking)
- More precise results with confidence scores

### 2. Quick Lookups

```bash
# Get a specific file (with fuzzy matching)
qmd get memory/2026-01-30.md

# Get from a specific line
qmd get memory/2026-01-30.md:50 -l 20

# Get multiple files by pattern
qmd multi-get "memory/2026-01-*.md"
```

### 3. Contextual Search

```bash
# Find all mentions of a topic
qmd search "job applications" --all --min-score 0.4

# Semantic search (understands meaning)
qmd vsearch "how do I send emails"

# Hybrid search with re-ranking (best quality)
qmd query "CERN application status" -n 3
```

### 4. Output Formats for Agents

```bash
# JSON output (structured data)
qmd query "recent tasks" --json -n 10

# File list (paths only)
qmd search "project" --files --min-score 0.5

# Markdown (for LLM context)
qmd query "decisions last week" --md --full
```

---

## Search Modes

| Command | Type | Speed | Use Case |
|---------|------|-------|----------|
| `search` | BM25 full-text | Fast | Exact keyword matching |
| `vsearch` | Vector semantic | Medium | Meaning-based retrieval |
| `query` | Hybrid + rerank | Slower | Best quality, complex queries |

**Recommendation:** Use `query` for important recalls, `search` for quick lookups.

---

## Score Interpretation

| Score Range | Meaning |
|-------------|---------|
| 0.8 - 1.0 | Highly relevant |
| 0.5 - 0.8 | Moderately relevant |
| 0.2 - 0.5 | Somewhat relevant |
| 0.0 - 0.2 | Low relevance |

Use `--min-score` to filter out noise.

---

## Integration with Clawdbot

### Replace memory_search calls

**Before:**
```typescript
memory_search("what was decided about Gmail")
```

**After:**
```bash
qmd query "Gmail decision" -n 5 --min-score 0.3 --md
```

### Daily Memory Workflow

1. **Heartbeat checks:** Use qmd to scan recent memory files
   ```bash
   qmd multi-get "memory/2026-01-*.md" --json
   ```

2. **Context retrieval:** Get relevant snippets instead of full files
   ```bash
   qmd query "tasks today" -n 3 --md
   ```

3. **Historical lookups:** Search across all time
   ```bash
   qmd query "when did we set up Trello" --all --min-score 0.4
   ```

---

## Maintenance

```bash
# Check status
qmd status

# Re-index collections (after adding new files)
qmd update

# Clean up cache
qmd cleanup

# Re-embed (after major changes)
qmd embed -f
```

---

## Advanced: MCP Server (Optional)

QMD can run as an MCP server for tighter agent integration:

**~/.claude/settings.json:**
```json
{
  "mcpServers": {
    "qmd": {
      "command": "qmd",
      "args": ["mcp"]
    }
  }
}
```

**Tools exposed:**
- `qmd_search` - BM25 keyword search
- `qmd_vsearch` - Vector semantic search
- `qmd_query` - Hybrid search with reranking
- `qmd_get` - Retrieve document by path/docid
- `qmd_multi_get` - Retrieve multiple documents
- `qmd_status` - Index health

---

## Models Used (Auto-Downloaded)

| Model | Purpose | Size |
|-------|---------|------|
| embeddinggemma-300M-Q8_0 | Vector embeddings | ~300MB |
| qwen3-reranker-0.6b-q8_0 | Re-ranking | ~640MB |
| qmd-query-expansion-1.7B | Query expansion | ~1.1GB |

**Cache location:** `~/.cache/qmd/models/`

---

## Troubleshooting

### Models not downloading
```bash
# Check internet connection
# Models auto-download on first use from HuggingFace
```

### Embeddings out of date
```bash
qmd embed -f  # Force re-embed
```

### Search returns no results
```bash
qmd status  # Check if collections are indexed
qmd update  # Re-index if needed
```

---

## Token Usage Tips

1. **Use `--min-score` aggressively** - Filter out low-relevance results
2. **Limit results with `-n`** - Don't retrieve more than needed
3. **Use `--files` for metadata** - Get paths/scores without content
4. **Prefer `search` over `query`** - When exact keywords work, skip the LLM reranking
5. **Multi-get with `--max-bytes`** - Limit file size to avoid huge documents

---

## Example: Heartbeat Memory Check

**Goal:** Check today's memory without loading the entire file

```bash
# Traditional approach (inefficient)
Read("memory/2026-01-31.md")  # Loads entire file (~2000 tokens)

# Optimized with qmd
qmd get "memory/2026-01-31.md" -l 50  # First 50 lines (~500 tokens)

# Even better - search for what matters
qmd query "tasks pending" -c memory --min-score 0.5 -n 3  # ~200 tokens
```

**Token savings:** 75-90% reduction

---

## References

- **GitHub:** https://github.com/tobi/qmd
- **Index location:** `~/.cache/qmd/index.sqlite`
- **Setup script:** (none needed, already configured)

---

**Created:** 2026-01-31  
**Status:** ✅ Active, embeddings in progress
