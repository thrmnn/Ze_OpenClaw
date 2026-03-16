# Job Application Pipeline - Action Plan

**Date:** 2026-03-16  
**Goal:** Get automated job application system working  
**Priority:** High (unblocks job search automation)

---

## 🎯 Current Situation

**What exists:**
- ✅ Career Experience Base (comprehensive resume data)
- ✅ Resume PDF (Resume_ML_2025.pdf)
- ✅ job-auto-apply skill installed
- ❌ OAuth tokens expired (Google Drive/Calendar)
- ❌ Pipeline not tested end-to-end

**Blocker:** OAuth authentication

---

## 🔧 Two-Phase Approach

### Phase 1: Fix OAuth (CRITICAL)
**Goal:** Stable Google API access

**Options:**

**A) Service Account (Best for automation)**
- Create GCP service account
- Download JSON key
- No token expiration
- Headless authentication

**B) OAuth with Auto-Refresh (Current approach)**
- Fix token refresh logic
- Ensure offline access
- Set up monitoring

**C) Alternative: No Google dependency**
- Use local file system only
- Store in Obsidian/Trello
- Simpler but less features

**Recommendation:** Try A (service account) for production reliability

---

### Phase 2: Build Pipeline
**Goal:** End-to-end automation

**Components:**

1. **Job Search Engine**
   - LinkedIn API/scraping
   - Indeed API
   - Manual job board monitoring
   - Keyword matching

2. **Resume Tailoring**
   - Extract job requirements
   - Match with Career Experience Base
   - Generate tailored resume
   - Export to PDF (LaTeX)

3. **Cover Letter Generation**
   - Template-based or AI-generated
   - Personalized per company/role
   - Include relevant achievements

4. **Application Submission** (Manual initially)
   - Generate all materials
   - Save to Drive/folder
   - Manual submission for now
   - Track in Trello/Obsidian

5. **Tracking System**
   - Application status (applied, interview, rejected)
   - Follow-up reminders
   - Analytics (response rate, etc.)

---

## 📋 Implementation Steps

### Step 1: OAuth Service Account (30 min)

```bash
# 1. Go to Google Cloud Console
# 2. Create service account
# 3. Enable APIs: Drive, Calendar, Gmail
# 4. Download JSON key
# 5. Save to ~/clawd/credentials/google-service-account.json
# 6. Share Drive folder with service account email
```

**Test:**
```python
from google.oauth2 import service_account
creds = service_account.Credentials.from_service_account_file(
    '~/clawd/credentials/google-service-account.json',
    scopes=['https://www.googleapis.com/auth/drive']
)
# Test Drive access
```

---

### Step 2: Job Search Config (15 min)

Create `~/clawd/job-pipeline-config.yaml`:
```yaml
search:
  keywords:
    - "ML Engineer"
    - "Robotics Engineer"
    - "Computer Vision Engineer"
    - "Perception Engineer"
  
  locations:
    - "Remote"
    - "Europe"
    - "United States"
  
  platforms:
    - linkedin
    - indeed
    - glassdoor

resume:
  template: ~/clawd/templates/resume-robotics.tex
  output: ~/clawd/output/resumes/

cover_letters:
  template: ~/clawd/templates/cover-letter.tex
  output: ~/clawd/output/cover-letters/

tracking:
  drive_folder: "Job Applications 2026"
  trello_board: "Job Pipeline"
  obsidian_path: "Projects/Job Application Pipeline/applications/"
```

---

### Step 3: Resume Tailoring Engine (1 hour)

**Script:** `~/clawd/scripts/job-tailor-resume.py`

```python
#!/usr/bin/env python3
"""
Tailor resume based on job description
"""

from pathlib import Path
import yaml
import re

def extract_job_requirements(job_desc):
    """Parse job description for keywords"""
    # Extract skills, requirements, responsibilities
    pass

def match_experience(requirements, career_base):
    """Match job requirements to career experience"""
    # Score relevance of each experience section
    # Return top matching experiences
    pass

def generate_tailored_resume(matches, template):
    """Generate LaTeX resume highlighting relevant experience"""
    # Fill template with matched experiences
    # Emphasize relevant skills
    pass

def main(job_url_or_desc):
    # 1. Extract job requirements
    # 2. Load Career Experience Base
    # 3. Match and score
    # 4. Generate resume PDF
    # 5. Save to output folder
    pass
```

---

### Step 4: Cover Letter Generator (30 min)

**Script:** `~/clawd/scripts/job-generate-cover-letter.py`

```python
def generate_cover_letter(company, role, job_desc, career_base):
    """
    Generate personalized cover letter
    
    Structure:
    1. Opening: Why this company/role
    2. Body: Relevant experiences (2-3 highlights)
    3. Closing: Call to action
    """
    # Use Claude API or template
    pass
```

---

### Step 5: Application Tracker (30 min)

**Options:**

**A) Trello-based:**
```
Lists:
- To Apply
- Applied
- Interview Scheduled
- Waiting Response
- Rejected
- Offer

Cards:
- Company + Role
- Application date
- Resume/cover letter links
- Status updates
```

**B) Obsidian-based:**
```markdown
# Job Applications

## Active

### Company Name - Role
- Applied: 2026-03-16
- Resume: [link]
- Cover Letter: [link]
- Status: Applied
- Follow-up: 2026-03-23
```

**C) Both (recommended)**

---

## 🚀 Quick Start (Today)

**Minimal viable pipeline:**

1. **Fix OAuth** (or skip Google for now)
2. **Manual workflow:**
   - Find job posting
   - Run: `python3 ~/clawd/scripts/job-tailor-resume.py "job_url"`
   - Gets: Tailored resume PDF
   - Manual: Apply on website
   - Track: Add to Trello

**Time:** 2-3 hours to set up

---

## 📊 Success Metrics

**Phase 1 (This week):**
- [ ] OAuth working OR alternative approach
- [ ] Resume tailoring script functional
- [ ] Applied to 3 jobs using system

**Phase 2 (Next week):**
- [ ] Cover letter generation working
- [ ] Tracking system operational
- [ ] Applied to 10 jobs total

**Phase 3 (Month 1):**
- [ ] Automated job search monitoring
- [ ] Follow-up reminders
- [ ] Analytics dashboard

---

## 🎯 Decision Point

**What to tackle first?**

**Option A: Fix OAuth properly (30 min)**
- Unblocks Google integration
- Enables Drive/Calendar features
- Required for full automation

**Option B: Build without Google (faster)**
- Local file system only
- Obsidian + Trello tracking
- Get pipeline working today

**Option C: Hybrid approach**
- Build core pipeline (local)
- Add Google integration later
- Fastest to first application

**Recommendation:** Option C (hybrid)
- Build resume tailor now
- Test with manual applications
- Add OAuth when needed

---

**Next steps?**
1. Choose approach (A/B/C)
2. Build resume tailoring script
3. Test with real job posting
4. Apply to first job

**Ready to start?**
