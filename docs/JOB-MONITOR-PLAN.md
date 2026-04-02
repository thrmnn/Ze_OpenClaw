# Job Monitoring Pipeline - Implementation Plan

## Overview

Autonomous job-monitoring agent for remote entry- to mid-level Machine Learning and Robotics Engineer roles.

**Objective:** Continuously discover, filter, validate, and report high-quality, currently open remote jobs, prioritizing precision over volume.

---

## Target Profile

### Experience
- 0–5 years
- Exclude: Senior/Staff/Principal/Lead

### Roles
- ML Engineer
- Applied ML
- AI Engineer (non-research)
- Robotics Engineer
- Robotics Software
- Computer Vision

### Work Mode
- Fully Remote / Remote-first

### Employment
- Full-time
- Contracts ≥6 months acceptable

### Technical Requirements
At least 2 keywords from:
- Python, PyTorch, TensorFlow, JAX
- ROS/ROS2
- Computer Vision, SLAM, RL, OpenCV
- Docker, Linux

### Exclusions
- Research-only roles
- PhD-required
- On-site only
- Vague or spam listings

---

## Sources to Monitor

### Major Job Boards
- LinkedIn Jobs
- Indeed
- Glassdoor
- ZipRecruiter

### Startup Boards
- Wellfound (AngelList)
- Y Combinator Jobs
- Startup Jobs

### Niche Boards
- MLjobs.ai
- AI Jobs Network
- Robotics Career Center
- Remote.co

### Direct Channels
- Company career pages (target list)
- Reddit: r/MachineLearningJobs
- Hacker News: Who's Hiring threads

---

## Validation Rules

### 1. Recency
- Posted/updated within 30 days
- Ignore stale listings

### 2. Legitimacy
- Real company with verifiable product/website
- Check company website exists and is active
- Avoid spam/MLM/training programs

### 3. Remote Eligibility
- Clear remote statement required
- Keywords: "fully remote", "remote-first", "work from anywhere"
- Exclude: "office-based", "on-site", "hybrid with required days"

### 4. Experience Alignment
- ≤5 years or equivalent
- Flag and exclude: Senior, Staff, Principal, Lead, Manager

### 5. Deduplication
- Cross-posted roles identified
- Track by company + role + location + date
- Keep highest-quality posting

---

## Scoring System (0–100)

### Role Relevance (30 points)
- **ML Engineer / Applied ML / AI Engineer:** 30pts
- **Robotics Engineer / Robotics Software:** 30pts
- **Computer Vision Engineer:** 28pts
- **Data Scientist (with ML focus):** 20pts
- **Research roles:** 0pts

### Experience Fit (25 points)
- **0-2 years / Entry-level:** 25pts
- **3-5 years / Mid-level:** 20pts
- **5+ years / Senior+:** 0pts

### Tech Stack Match (25 points)
**High-value keywords (5pts each):**
- PyTorch, TensorFlow, JAX
- ROS, ROS2

**Medium-value keywords (3pts each):**
- Python, Computer Vision, SLAM
- OpenCV, Docker, Linux, RL

**Calculation:** Sum of matching keywords, max 25pts

### Remote Clarity (10 points)
- **"Fully remote" / "100% remote":** 10pts
- **"Remote-first":** 8pts
- **"Remote eligible":** 5pts
- **Ambiguous:** 0pts

### Company Quality (10 points)
- **Well-known product, funded:** 10pts
- **Established, lesser known:** 7pts
- **Startup, unverified:** 4pts
- **Suspicious/unknown:** 0pts

### Threshold
**Report only roles with Score ≥70**

---

## Output Format

For each role:
```
Company | Role | Match Score
Remote Scope | Experience Level
Key Tech Stack: Python, PyTorch, ROS2
✓ Strong product-market fit in robotics
✓ Clear growth path for ML engineers
Application: [link]
Posted: 2026-01-28
```

### Grouping
- **Best Matches (≥85):** Top-tier opportunities
- **Robotics Focus (70-84):** Robotics-heavy roles
- **ML Focus (70-84):** ML-heavy roles

---

## Operating Principle

**Favor signal over volume.**

If the market is thin, report trends rather than lowering standards:
- "Found 3 matches this week (down from 5 last week)"
- "Robotics market is thin; most roles require 8+ years"
- "Increasing demand for ROS2 experience observed"

---

## Implementation Phases

### Phase 1: Research & Design (Week 1)
- [ ] Define sources and APIs
- [ ] Design validation rules
- [ ] Design scoring algorithm
- [ ] Plan deduplication strategy

### Phase 2: Core Implementation (Week 2-3)
- [ ] Job fetcher (polling + parsing)
- [ ] Validation engine
- [ ] Scoring system
- [ ] Deduplication logic
- [ ] Output formatter

### Phase 3: Automation (Week 3-4)
- [ ] Scheduled monitoring (cron/systemd)
- [ ] State management (SQLite)
- [ ] Trello/Telegram integration
- [ ] Status dashboard

### Phase 4: Testing & Calibration (Week 4)
- [ ] Test with real jobs
- [ ] Calibrate scoring weights
- [ ] Tune precision/recall
- [ ] Edge case handling

### Phase 5: Documentation (Ongoing)
- [ ] User guide
- [ ] Technical documentation
- [ ] Development guide
- [ ] Operations guide

---

## Tech Stack

### Core
- **Python 3.11**
- **BeautifulSoup4 / Scrapy** - Web scraping
- **Requests** - API calls
- **Schedule** - Job scheduling

### Data & State
- **SQLite** - Job history and state
- **Pandas** - Data processing
- **Hashlib** - Deduplication

### Integration
- **Trello API** - Card creation
- **Telegram Bot API** - Notifications
- **SMTP** - Email reports (optional)

### Deployment
- **Cron / systemd timer** - Automation
- **Logging** - Python logging module
- **JSON** - Configuration files

---

## File Structure

```
clawd/
├── scripts/
│   └── job-monitor/
│       ├── main.py              # Entry point
│       ├── fetcher.py           # Source polling
│       ├── validator.py         # Validation rules
│       ├── scorer.py            # Scoring algorithm
│       ├── deduplicator.py      # Duplicate detection
│       ├── reporter.py          # Output formatting
│       ├── config.json          # Configuration
│       └── db.py                # SQLite helpers
├── docs/
│   ├── JOB-MONITOR.md           # User guide
│   ├── JOB-MONITOR-TECH.md      # Technical docs
│   ├── JOB-MONITOR-DEV.md       # Development guide
│   ├── JOB-MONITOR-OPS.md       # Operations guide
│   └── JOB-SOURCES.md           # Source documentation
├── data/
│   └── job-monitor.db           # SQLite database
└── logs/
    └── job-monitor.log          # Application logs
```

---

## Success Metrics

### Quality
- **Precision ≥80%:** Reported jobs are actually relevant
- **False positives <20%:** Bad jobs scoring ≥70
- **Score explanations:** Clear why each job matched

### Coverage
- **Sources:** Monitor ≥10 diverse sources
- **Update frequency:** Check every 6-12 hours
- **History retention:** 30 days of job data

### Automation
- **Uptime:** Runs reliably without manual intervention
- **Error handling:** Graceful degradation on source failures
- **Reporting:** Daily digest delivered consistently

---

## Future Enhancements

### Advanced Features
- **ML-based scoring:** Train model on accepted/rejected jobs
- **Company research:** Automatic glassdoor/crunchbase lookup
- **Salary estimation:** Predict salary range from posting
- **Application tracking:** Link to applied jobs

### Intelligence
- **Trend detection:** "ROS2 demand up 30% this month"
- **Gap analysis:** "Few entry-level robotics roles lately"
- **Market insights:** "Most companies require 3+ years"

### Integrations
- **Calendar:** Add deadlines for application closing dates
- **CRM:** Track application pipeline
- **Resume optimizer:** Match keywords to improve chances

---

## Related Documents

- **`docs/JOB-APPLICATION-PIPELINE.md`** - Existing application automation
- **`skills/job-auto-apply/SKILL.md`** - Auto-apply skill integration
- **`TOOLS.md`** - Trello and Telegram configuration

---

**Created:** 2026-01-31  
**Status:** Planning phase  
**Next:** Research sources and design validation rules
