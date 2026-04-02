# Project — Job Application Pipeline

> Extracted from MEMORY.md on 2026-04-02

## Architecture

```
Position Radar         → scans 25+ companies daily (Greenhouse/Lever/Ashby APIs)
  ~/clawd/job-pipeline/discovery/discover.py
  Scoring: 0-100 rubric, alert threshold ≥70, cron 9am Brazil
  Top match: Apptronik Senior Autonomy SW Eng = 83/100

JOB_QUEUE.md           → URL queue in Ob_Business_Vault
  Auto-populated by Position Radar when score ≥65
  Manual URLs also supported

process_queue.py       → batch processor (reads queue, runs pipeline per job)
  ~/clawd/job-pipeline/process_queue.py
  Uses: ~/miniconda3/bin/conda run -n job-pipeline python process_queue.py

7-Agent Pipeline       → per job: fit analysis + resume tailoring + narratives + audit
  LLM: claude --print -p
  Profile: data/theo-profile.json

Output per job:
  - application.json (fit score, tailored bullets, motivation, audit)
  - resume.pdf (fpdf2, ATS-safe single column)
  - cover_letter.pdf (professional letter format)
  - Saved to: Ob_Business_Vault/Projects/Job Application Pipeline/results/{slug}/
  - Uploaded to: Google Drive → Job Applications/2026-03/{Company} — {Role}/

Application Tracker    → SQLite at ~/clawd/job-pipeline/tracker.db
  Tables: applications, rounds, documents
  CLI: conda run -n job-pipeline python -m tracker.cli status
  Obsidian notes: .../Job Application Pipeline/applications/{slug}/index.md
  Daily digest cron: 9am → Telegram (silent if no active apps)
```

## Path Note
- Pipeline is at `~/clawd/job-pipeline/` (NOT `~/projects/job-pipeline/`)
- Discovery module: `~/clawd/job-pipeline/discovery/discover.py`

## Bugs Fixed (2026-03-18/19)
- `location=None` Amazon bug: patched in all scrapers
- Path inconsistency: tracker notes now use `job_slug`
- ATS score field: `ats_score` → `ats_optimization_score`
- Resume tailoring bug fixed: verbatim copy detection working (commits: `d43d3fe`, `50b69af`, `f0008c5`)
- Scorer recalibrated: Apptronik roles now score ~55-70% (was 31%)

## Position Radar Companies (25+)
Apptronik, Boston Dynamics, Figure AI, Waymo, Nuro, Agility Robotics, Shield AI, Anduril, Zipline, Skydio, Climeworks, NVIDIA, Tesla, 1X Technologies, Amazon Robotics, + more via Greenhouse/Lever/Ashby
