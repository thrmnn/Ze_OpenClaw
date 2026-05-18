# LLM Wiki — Adaptation Proposal for the Zé / Obsidian Stack

> Analysis of Karpathy's LLM Wiki pattern, audit of the current knowledge base, and a concrete migration plan.
> Written 2026-04-05.

---

## What you already have (the audit)

### Infrastructure (solid)
- **4 Obsidian vaults**, 213 .md files, 1.95 MB total, each with a PARA-style layout (`Archive/ Areas/ Daily/ Inbox/ Projects/ Resources/ Templates/`).
- **QMD** (hybrid BM25 + vector search) indexing all 4 vaults + `~/clawd/memory/` + workspace scripts. 6 collections, 5-minute update interval, 6 max results.
- **Syncthing** bidirectional sync between desktop and VPS for both vaults and clawd.
- **Memory dir** (`~/clawd/memory/`): 28 daily logs, 10 topic files, 11 briefs, 40 x-cache files.
- **Scripts** for daily note generation, morning routines, weekly reviews.

### What's missing (the gaps Karpathy's pattern would fill)

| Gap | Current state | Target |
|-----|--------------|--------|
| **No schema** | Zero CLAUDE.md / AGENTS.md in any vault. LLM has no rules for how to maintain content. | Each vault gets a schema. |
| **Log-first, not wiki-first** | Memory is 28 daily logs + 10 scattered topics. Knowledge is temporal, not topical. | Knowledge compiled into persistent, interlinked entity/concept pages. Logs become inputs, not outputs. |
| **Read-only LLM** | Zé reads vaults via QMD. Never writes back. | Zé writes and maintains wiki pages. You curate sources and ask questions. |
| **Siloed vaults** | 4 disconnected subgraphs. Zero intervault links. Business jobs don't reference Research career research. | Cross-vault awareness via a shared wiki layer or explicit bridge pages. |
| **No index + log** | Each vault has a `00_dashboard.md` and `VAULT-INDEX.md` but they're manually maintained and drift. | LLM-maintained `index.md` (content catalog) + `log.md` (chronological record of changes). |
| **No lint / health check** | Nobody audits orphan pages, stale claims, missing cross-refs. | Periodic LLM lint pass. Flag contradictions, orphans, gaps. |
| **No ingest workflow** | Sources (articles, papers, podcasts) are dropped into `Inbox/` but not systematically processed. | Formal ingest: source → LLM reads → summary page → entity updates → index update → log entry. |

---

## The Karpathy pattern, mapped to your stack

### Karpathy's 3 layers

| Layer | What | Your equivalent |
|-------|------|-----------------|
| **Raw sources** | Immutable collection of articles, papers, data. LLM reads but never modifies. | `Inbox/` + `Resources/` folders in each vault, plus external feeds (web clips, PDFs, Telegram forwards). Already exist. |
| **The wiki** | LLM-generated markdown pages. Summaries, entity pages, concept pages, comparisons. LLM owns this entirely. | **Does not exist yet.** Closest is `~/clawd/memory/topics/` (10 files) but it's ad-hoc and stale. |
| **The schema** | CLAUDE.md / AGENTS.md telling the LLM how to maintain the wiki — structure, conventions, workflows. | **Does not exist yet.** No per-vault schema. No conventions doc for Zé. |

### Proposed instantiation

Keep your 4-vault structure (it maps well to Karpathy's "domain" concept). Add a wiki layer **inside each vault** at `Wiki/`. Add a schema file per vault.

```
Ob_Research_Vault/
├── Inbox/                  ← raw sources (articles, papers, web clips)
├── Resources/              ← reference material
├── Wiki/                   ← NEW: LLM-maintained knowledge pages
│   ├── index.md            ← catalog of all wiki pages (LLM-maintained)
│   ├── log.md              ← chronological ingest/query/lint log
│   ├── entities/           ← people, institutions, projects
│   ├── concepts/           ← topics, methods, theories
│   ├── sources/            ← one summary page per ingested source
│   └── synthesis/          ← comparisons, analyses, cross-cutting themes
├── Projects/               ← active research projects (mixed human/LLM)
├── Daily/                  ← daily notes (human-driven, template-generated)
├── Templates/              ← note templates
├── Archive/                ← completed/abandoned items
└── CLAUDE.md               ← NEW: vault schema (LLM conventions)
```

The `Wiki/` folder is the Karpathy "wiki layer". Everything in it is LLM-generated and LLM-maintained. You read it; Zé writes it. `CLAUDE.md` is the schema.

---

## What each piece does

### CLAUDE.md (schema file, one per vault)

Tells Zé how to maintain this specific vault's wiki. Example for `Ob_Research_Vault`:

```markdown
# Ob_Research_Vault — Schema

## Role
Zé maintains the Wiki/ directory. Sources in Inbox/ and Resources/ are read-only
(never modify). Everything else (Projects/, Daily/) is human-editable.

## Page types
- **Source page** (Wiki/sources/): one per ingested article/paper. Title, authors,
  key claims, relevance to active projects, tags.
- **Entity page** (Wiki/entities/): one per person, lab, institution, project
  that appears in >1 source. Updated on every ingest.
- **Concept page** (Wiki/concepts/): one per topic, method, or theory.
  Cross-references to entities and sources. Updated when new sources add or
  challenge claims.
- **Synthesis page** (Wiki/synthesis/): comparisons, literature reviews,
  cross-cutting analyses. Created on query or lint.

## Ingest workflow
1. User drops a file into Inbox/ and tells Zé to process it.
2. Zé reads the source, writes Wiki/sources/<title>.md.
3. Zé updates or creates entity and concept pages.
4. Zé updates Wiki/index.md (add new page entries).
5. Zé appends to Wiki/log.md.
6. Zé tells user what changed (1-3 sentences).

## Conventions
- All wiki pages use YAML frontmatter: type, created, updated, source_count, tags.
- Wiki-links use [[relative path]] format: [[entities/CERN]], [[concepts/LLM fine-tuning]].
- Tags: #status/active, #status/stale, #confidence/high, #confidence/low.
- When new data contradicts an existing page, add a ⚠️ section at the top.
```

### index.md (LLM-maintained catalog)

```markdown
# Wiki Index — Ob_Research_Vault

## Entities (12)
- [[entities/CERN]] — 3 sources, last updated 2026-03-15
- [[entities/Andrej Karpathy]] — 1 source, last updated 2026-04-05
...

## Concepts (8)
- [[concepts/Retrieval-Augmented Generation]] — 2 sources
- [[concepts/LLM Wiki pattern]] — 1 source, NEW
...

## Sources (15)
- [[sources/Karpathy - LLM Wiki (2026)]] — ingested 2026-04-05
...

## Synthesis (2)
- [[synthesis/RAG vs Wiki pattern comparison]] — 2026-04-05
...
```

### log.md (append-only timeline)

```markdown
## [2026-04-05] ingest | Karpathy - LLM Wiki
- Source: Inbox/karpathy-llm-wiki.md
- Created: sources/Karpathy - LLM Wiki (2026).md
- Updated: concepts/Retrieval-Augmented Generation.md (added contrast section)
- Created: concepts/LLM Wiki pattern.md
- Created: entities/Andrej Karpathy.md
- Updated: index.md (+3 entries)
```

---

## What changes vs. your current workflow

### Before (current)
1. You encounter an article → clip to Inbox/ (or skip entirely).
2. You read it yourself (or don't).
3. You might mention insights in a daily log.
4. Knowledge exists only in the source file and your head.
5. Zé reads context via QMD when asked, re-deriving from raw sources each time.

### After (with LLM Wiki)
1. You encounter an article → clip to Inbox/.
2. You tell Zé: "ingest `Inbox/article-name.md`".
3. Zé reads the source, writes a summary page, updates entity and concept pages, updates the index, logs the change.
4. Knowledge is compiled, cross-referenced, and persistent in Wiki/.
5. When you (or Zé) ask a question, the answer is pre-synthesized in the wiki. QMD still works, but now it searches compiled knowledge, not raw sources.
6. Periodically, Zé lints the wiki: flags stale claims, orphan pages, contradictions, missing cross-references.

**The human's job doesn't change** — you curate sources, ask questions, think about meaning. The bookkeeping (summarizing, linking, updating, consistency-checking) is fully delegated.

---

## Migration plan (incremental, not big-bang)

### Phase 1 — Schema + structure (30 min, no LLM calls)
- Create `CLAUDE.md` in each vault (adapt the template above per domain).
- Create `Wiki/`, `Wiki/index.md`, `Wiki/log.md`, `Wiki/entities/`, `Wiki/concepts/`, `Wiki/sources/`, `Wiki/synthesis/` in each vault.
- Index.md starts empty: just headers for each section.
- Update QMD config to also index `Wiki/**/*.md` (it's already indexing `**/*.md` so this is automatic).

### Phase 2 — Seed from existing content (1-2 hours)
- Run a one-time "ingest everything in Resources/" pass per vault via Zé/Claude Code.
- For each vault, Zé reads existing Resources/ and Projects/ files, extracts entities and concepts, writes initial wiki pages.
- This gives you a baseline wiki with 20-50 pages per vault — enough to feel useful immediately.
- Track progress in `Wiki/log.md`.

### Phase 3 — Live ingest workflow (ongoing)
- Whenever you clip a new article to `Inbox/`, tell Zé to ingest it.
- Can be ad-hoc ("ingest this") or scheduled (a cron that checks `Inbox/` for new files daily).
- Each ingest touches 5-15 wiki pages. Zé handles all the bookkeeping.

### Phase 4 — Lint + query (weekly)
- Weekly lint: Zé scans the wiki for orphans, stale pages, contradictions, missing entity pages.
- Query-driven growth: questions you ask that require synthesis get filed as new `Wiki/synthesis/` pages.
- Obsidian graph view becomes useful — you can see the knowledge graph growing.

### Phase 5 — Cross-vault awareness (optional, later)
- Create a `Wiki/bridges/` folder for pages that span vaults (e.g., "Career trajectory" linking Research entities to Business job applications to Personal goals).
- Or: create a 5th vault `Ob_Meta_Vault` that is purely cross-cutting synthesis. Zé maintains it; you browse it.

---

## What NOT to change

- **Daily notes**: keep them human-driven. They're your journal, not the wiki's problem.
- **Project files**: keep them in `Projects/`, editable by both you and Zé. The wiki summarizes but doesn't replace them.
- **QMD**: keep it. It's the search layer. The wiki makes QMD better (it now searches compiled knowledge, not just raw notes).
- **4-vault split**: keep it. Domain separation is useful. Karpathy uses one wiki because he has one domain at a time; you have 4 concurrent domains.
- **PARA structure**: keep `Archive/ Areas/ Daily/ Inbox/ Projects/ Resources/ Templates/`. The wiki layer is additive (`Wiki/`), not a replacement.

---

## Cost implications

Each ingest touches 5-15 wiki pages. With Claude Sonnet at $3/M input tokens:
- Average wiki page: ~500 tokens. Reading 15 pages = 7.5 K tokens.
- Writing 15 pages: ~7.5 K output tokens × $15/M = $0.11.
- Reading the source: ~2 K tokens for a typical article.
- **Total per ingest: ~$0.15-0.30** (well within the €20/month budget at 50-100 ingests/month).
- Lint pass: ~$0.50-1.00 per vault per week.

But this assumes sessions are short and don't bloat — which circles back to the burn prevention design in `TOKEN-BURN-AUDIT.md`. The wiki workflow is cost-safe only with proper session rotation.

---

## Implementation note

Karpathy says "this document is intentionally abstract — share it with your LLM agent and work together to instantiate it." That's exactly what I propose: start with Phase 1 (create the scaffolding), seed Phase 2 with a focused vault (probably Research — smallest, most structured), iterate the schema based on what works, then roll out to the other 3 vaults.

The schema file (`CLAUDE.md`) is the most important artifact. Get that right for one vault and the rest follow.

---

## Related docs

- `TOKEN-BURN-AUDIT.md` — cost model for API calls (affects wiki ingest budget)
- `PLUMBING-TODO.md` — infrastructure gaps that affect wiki reliability
- `HEARTBEAT.md § Memory Search` — existing QMD search integration
- `~/clawd/memory/topics/` — proto-wiki content that can be migrated
