# Position Radar Scan — April 6, 2026

**Time:** Monday, April 6, 12:01 PM UTC / 2026-04-06 12:01  
**Run Date:** 2026-04-06  

## Summary

| Metric | Value |
|--------|-------|
| Sources scanned | 4 |
| Jobs fetched | 6 |
| New (unseen) | 0 |
| Hard-filtered | 0 |
| Scored | 0 |
| Queue (≥65) | 0 |
| **Alert (≥70)** | **0** |
| Written to queue | 0 |
| DB total seen | 531 |

## Status

**No new jobs discovered.** All 6 fetched were duplicates from prior scans.

## Sources & Results

| Source | Jobs | Status |
|--------|------|--------|
| Greenhouse | 0 | ❌ ERROR: Missing lxml parser |
| Lever | 6 | ✅ 6 found, 0 new |
| LinkedIn | 0 | ❌ ERROR: Missing lxml (5 searches failed) |
| Wellfound | 0 | ✅ Scanned, 0 found |

## Errors & Warnings

1. **Greenhouse Parser** — "Couldn't find a tree builder with the features you requested: lxml"
   - All Greenhouse searches failed
   
2. **LinkedIn Parser** — Same lxml error on all 5 search queries:
   - Robotics Software Engineer
   - Perception Engineer
   - Computer Vision Engineer remote
   - Machine Learning Engineer robotics
   - Autonomy Engineer

3. **Lever Dead Links** (non-critical):
   - Machina Labs (machinalabs): 404
   - Viam (viam): 404

## Action Items

**Fix:** Install lxml parser dependency to resume Greenhouse & LinkedIn scraping.
```bash
pip install lxml
```

Next scheduled scan: Daily at ~12:01 PM UTC
