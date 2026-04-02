# Archive — March 2026 Sprint Logs

> Extracted from MEMORY.md on 2026-04-02. Historical build logs — not needed in hot context.

## 2026-03-18 — Full Parallel Build Sprint (6 agents, ~15 min)

| Project | What was built |
|---------|---------------|
| LAI Paper | Editorial polish, tree count fix (→12,350), 15 LaTeX fixes, clean compile |
| AI Agency MVP | Full RAG scaffold: Qdrant+Docker, LlamaIndex ingestion, Streamlit chat UI |
| Brisa+ Slides | 6-slide deck (PK style, speaker notes) + 5-presentation calendar in Obsidian |
| Personal Website | 3 project descriptions + bonus LAI. Hugo build ✅ 168 pages. CI/CD configured |
| Job Pipeline | Multi-platform discovery: Greenhouse, Lever, LinkedIn, Wellfound |
| Mission Control | Tasks Kanban (/tasks), Agents panel, /api/pixel-agents endpoint |

## 2026-03-18 — Afternoon Sprint Results (Waves 2-4, ~55 agent sessions)

### LAI Paper
- All 5 blocking submission checklist items fixed and committed (`d35b6c5`)
- Discussion §4.1-4.3 reconstructed (were missing from source .tex)
- PDF compiles clean: 22 pages

### Brisa+
- 3 commits: bibliography hardened, Nature Cities claims mapped, reviewer prebuttal language added
- Branch: `literature-review-expansion`

### Mission Control
- `/radar` page added, UI polished (drag-and-drop, stat indicators)
- Deployed to Vercel

### Website
- `public/` excluded from git
- Hugo + blox-tailwind versions pinned

### AI Agency MVP
- Streamlit UI polished, PDF support confirmed
- DEMO_SCRIPT.md, PITCH_DECK_OUTLINE.md, sample_queries.md added

## 2026-03-19 — Wave 2 Sprint

### Job Pipeline
- Tailoring bug fixed (commits: d43d3fe, 50b69af, f0008c5)
- Scorer recalibrated
- LLM-first v2: switched to Opus direct call

### Website
- GitHub Actions workflow fixed (5 commits)
- Deploy succeeded 16:13 UTC

### Mission Control
- /api/status fixed + deployed (`fc8dbd7`)

### Key Decision (2026-03-19)
- Théo handles research manually (LAI, Brisa+) — too sensitive for autonomous agents
- Zé runs everything else in parallel
