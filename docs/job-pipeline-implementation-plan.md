# Job Application Pipeline - Implementation Plan

**Status:** Architecture defined, ready to implement  
**Timeline:** Phased approach (3-4 days of focused work)

---

## Phase 1: Foundation (Day 1)

### 1.1 Base Profile Setup
**Input needed from Théo:**
- Current resume (PDF or markdown)
- List of ML projects with:
  - Project name
  - Problem/context
  - Your role and actions
  - Technologies used
  - Quantified results (metrics, scale, impact)
  - Deployment/production status

**Deliverable:**
- `data/candidate-profile.json` - Structured base profile
- Skill→evidence mapping
- Project database

### 1.2 Environment Setup
```bash
pip install langchain langgraph langchain-anthropic pydantic
```

**Deliverable:**
- `job-pipeline/` directory structure
- Agent framework skeleton
- Pydantic schemas for all agents

---

## Phase 2: Core Agents (Day 2)

### 2.1 Job Understanding Agent
**Implementation:**
- Job URL → extract job description (web scraping + cleanup)
- Parse requirements (required vs preferred)
- Extract ML domain, seniority, keywords
- Output structured JSON

**Testing:**
- Test with 3 sample job postings (different domains: CV, NLP, MLOps)

### 2.2 Candidate Knowledge Agent
**Implementation:**
- Load base profile from JSON
- Build skill→evidence index
- Validate quantified impacts
- Flag expertise boundaries

**Testing:**
- Parse Théo's resume and projects
- Verify no hallucinations

---

## Phase 3: Tailoring Agents (Day 3)

### 3.1 Fit & Gap Agent
**Implementation:**
- Compare job requirements vs candidate profile
- Score matches (strong, partial, gap)
- Recommend positioning strategy

### 3.2 Resume Tailoring Agent
**Implementation:**
- Rewrite bullets with impact-first language
- Inject job-specific keywords (ATS-safe)
- Reorder sections by relevance

### 3.3 Project Storytelling Agent
**Implementation:**
- Select 1-2 most relevant projects
- Generate STAR narratives
- Add technical depth and metrics

---

## Phase 4: Quality & Integration (Day 4)

### 4.1 Consistency & Risk Agent
**Implementation:**
- Audit all outputs for contradictions
- Calculate interview defensibility score
- Flag over-claiming risks

### 4.2 Email Integration
**Implementation:**
- Generate tailored resume (markdown → PDF)
- Compose email with attachments
- Send via Gmail API

### 4.3 Tracking System
**Implementation:**
- Save tailored outputs with job metadata
- Track application status
- Generate analytics (fit scores, success rate)

---

## Directory Structure

```
job-pipeline/
├── agents/
│   ├── __init__.py
│   ├── job_understanding.py
│   ├── candidate_knowledge.py
│   ├── fit_gap.py
│   ├── resume_tailoring.py
│   ├── project_storytelling.py
│   ├── motivation.py
│   └── consistency_risk.py
├── schemas/
│   ├── __init__.py
│   ├── job.py              # Job requirements schema
│   ├── candidate.py        # Candidate profile schema
│   ├── fit.py              # Fit analysis schema
│   └── outputs.py          # Tailored outputs schema
├── orchestrator.py         # LangGraph DAG
├── utils/
│   ├── job_scraper.py      # Extract job description from URL
│   ├── pdf_generator.py    # Markdown → PDF resume
│   └── email_sender.py     # Gmail API integration
├── prompts/                # Agent prompt templates
│   ├── job_understanding.txt
│   ├── resume_tailoring.txt
│   └── ...
├── data/
│   ├── candidate-profile.json    # Base profile (persistent)
│   └── applications/             # Tailored outputs per job
│       └── {job_id}/
│           ├── job_description.json
│           ├── tailored_resume.md
│           ├── tailored_resume.pdf
│           ├── project_narratives.md
│           ├── motivation.txt
│           └── audit_report.json
└── main.py                 # CLI entry point
```

---

## CLI Interface

```bash
# Run full pipeline
python job-pipeline/main.py apply --url "https://jobs.cern.ch/..."

# Test individual agent
python job-pipeline/main.py test-agent --agent job_understanding --url "..."

# Review application
python job-pipeline/main.py review --job-id abc123

# List applications
python job-pipeline/main.py list --status pending
```

---

## What I Need from You (Théo)

### Immediate (to start Phase 1):

1. **Your current resume** (any format: PDF, docx, markdown)

2. **ML Projects list** - For each project, provide:
   ```
   Project: [Name]
   Problem: [What needed solving?]
   Your Role: [What did you specifically do?]
   Tech Stack: [Technologies, frameworks, tools]
   Results: [Metrics - accuracy, latency, scale, cost reduction, etc.]
   Deployment: [Production status, scale, users]
   ```

3. **Target Role Profile:**
   - Seniority level you're targeting (junior, mid, senior, staff?)
   - ML domains of interest (CV, NLP, RL, MLOps, Research?)
   - Engineering focus (research, production, infra, full-stack ML?)
   - Location preferences (US, Switzerland, remote?)
   - Visa status / work authorization

4. **CERN Application:**
   - Job URL
   - Any specific requirements or focus areas
   - Deadline

### Optional (can add later):
- Publications/papers (if any)
- GitHub profile highlights
- Certifications
- Preferred cover letter tone (formal, conversational, technical)

---

## Success Criteria

**Phase 1 Complete:** Base profile structured, all projects documented  
**Phase 2 Complete:** Job understanding + candidate knowledge agents working  
**Phase 3 Complete:** Full tailoring pipeline producing resume + projects  
**Phase 4 Complete:** Email sent with tailored materials, tracking in place

**Final Test:** Send you a real tailored application for CERN position, you review for:
- Truthfulness (100% defensible)
- Impact density (every line adds value)
- Role fit (clear alignment with job requirements)
- Interview readiness (confident to discuss every claim)

---

## Timeline

- **Day 1:** Base profile setup (need your resume + projects)
- **Day 2:** Job + Candidate agents
- **Day 3:** Tailoring agents
- **Day 4:** Quality + email integration

**Total:** 3-4 days of focused work (depends on resume/project documentation completeness)

---

## Next Action

**Send me:**
1. Your current resume
2. Description of 3-5 key ML projects (format above)
3. CERN job URL

I'll start building the foundation and have a working prototype ready for the CERN application. 😌
