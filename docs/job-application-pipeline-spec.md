# Job Application Tailoring Pipeline - Architecture Specification

**Last Updated:** 2026-01-28

## Objective

Transform a base candidate profile (resume + projects) and a job description into a job-specific, truthful, high-impact application optimized for ML Engineer roles.

## Workflow (User Experience)

1. User sends job offer URL
2. System extracts job description
3. Multi-agent pipeline tailors resume + cover letter + projects
4. System emails user when complete (with tailored materials attached)

## Architecture: LangChain Multi-Agent System

**Framework:** LangGraph or explicit DAG  
**Pattern:** Router/orchestrator coordinating specialized agents  
**Output:** Structured outputs (Pydantic/JSON schemas) per agent

---

## Agents & Responsibilities

### 1. Job Understanding Agent
**Input:** Job description (raw text or URL)  
**Output:** Structured job requirements

**Responsibilities:**
- Parse job description
- Extract required vs preferred skills
- Identify ML domain focus (CV, NLP, RL, MLOps, etc.)
- Detect engineering expectations (scale, infra, research)
- Extract seniority signals
- Identify screening keywords (ATS)
- Infer interviewer evaluation criteria

**Output Schema:**
```json
{
  "required_skills": ["python", "pytorch", "distributed-training"],
  "preferred_skills": ["kubernetes", "mlflow"],
  "ml_domain": "computer-vision",
  "engineering_focus": "production-ml",
  "seniority": "mid-senior",
  "screening_keywords": ["gpu", "inference", "model-serving"],
  "evaluation_criteria": ["system-design", "ml-fundamentals", "production-exp"]
}
```

---

### 2. Candidate Knowledge Agent
**Input:** Base resume + projects (markdown or JSON)  
**Output:** Structured candidate profile

**Responsibilities:**
- Parse base resume/projects
- Build skill→evidence mapping
- Extract quantified impacts
- Generate project summaries
- Define explicit expertise boundaries (no embellishment)

**Output Schema:**
```json
{
  "skills": {
    "pytorch": {
      "evidence": ["Built image classification pipeline", "Fine-tuned ViT models"],
      "years": 2,
      "proficiency": "intermediate"
    }
  },
  "impacts": [
    {"metric": "latency", "improvement": "40% reduction", "context": "model inference"}
  ],
  "projects": [
    {
      "name": "Vision Transformer for Medical Imaging",
      "summary": "...",
      "tech_stack": ["pytorch", "transformers", "docker"],
      "scale": "1M images"
    }
  ],
  "boundaries": {
    "no_experience_with": ["production-kubernetes", "distributed-training-at-scale"]
  }
}
```

---

### 3. Fit & Gap Agent
**Input:** Job requirements + Candidate profile  
**Output:** Alignment analysis

**Responsibilities:**
- Compare job needs vs candidate evidence
- Identify strong matches
- Identify partial matches
- Flag critical gaps
- Recommend positioning angle (e.g., "infra-heavy ML", "applied research")

**Output Schema:**
```json
{
  "strong_matches": [
    {"skill": "pytorch", "evidence_strength": "high", "relevance": "core"}
  ],
  "partial_matches": [
    {"skill": "mlops", "evidence": "limited", "can_emphasize": "docker + ci/cd exp"}
  ],
  "critical_gaps": ["kubernetes at scale"],
  "positioning": "applied-ml-with-production-focus",
  "fit_score": 0.78
}
```

---

### 4. Resume Tailoring Agent
**Input:** Candidate profile + Fit & Gap analysis + Job requirements  
**Output:** Tailored resume bullets

**Responsibilities:**
- Rewrite resume bullets with impact-first language
- Align language to role (engineering vs research)
- Ensure ATS-safe keywords
- Reorder sections by relevance
- No buzzwords without evidence

**Output Schema:**
```json
{
  "tailored_bullets": [
    {
      "original": "Built ML pipeline for image classification",
      "tailored": "Architected production ML pipeline processing 1M+ medical images/day with PyTorch, reducing inference latency 40% through model optimization and GPU batching",
      "emphasis": ["scale", "impact", "technical-depth"],
      "keywords": ["pytorch", "gpu", "latency", "production"]
    }
  ],
  "section_order": ["experience", "projects", "skills", "education"]
}
```

---

### 5. Project Storytelling Agent
**Input:** Projects + Job focus + Fit analysis  
**Output:** 1-2 deep project narratives (STAR format)

**Responsibilities:**
- Generate concise STAR-style ML project narratives
- Problem framing
- Modeling/system choices
- Trade-offs explained
- Metrics (accuracy, scale, latency, cost)
- Deployment or scale where relevant

**Output Schema:**
```json
{
  "narratives": [
    {
      "project": "Vision Transformer Medical Imaging",
      "situation": "Hospital needed automated disease detection from X-rays with <1s latency",
      "task": "Build production-ready CV model handling 1M+ daily images",
      "action": "Fine-tuned ViT on 500K labeled medical images, optimized inference with TorchScript and GPU batching, deployed via FastAPI + Docker",
      "result": "Achieved 94% accuracy, 400ms p99 latency, reduced manual review by 60%",
      "trade_offs": "Chose ViT over CNN for transfer learning speed despite higher inference cost",
      "technical_depth": "high",
      "relevance_score": 0.92
    }
  ]
}
```

---

### 6. Motivation Agent (Optional)
**Input:** Job description + Candidate profile + Fit analysis  
**Output:** 3-5 sentence motivation paragraph

**Responsibilities:**
- Generate role-specific motivation
- Explicit team/problem alignment
- No generic passion statements
- No resume repetition
- Authentic connection to role

**Output Schema:**
```json
{
  "motivation": "I'm particularly drawn to this role because of [specific team/problem]. My experience with [relevant project] directly aligns with your focus on [job-specific challenge]. I'm excited by the opportunity to [specific contribution].",
  "authenticity_score": 0.85
}
```

---

### 7. Consistency & Risk Agent
**Input:** All tailored outputs + Original profile  
**Output:** Final audit + defensibility score

**Responsibilities:**
- Detect contradictions across outputs
- Flag over-claiming risks
- Check seniority mismatch
- Calculate interview defensibility score
- Ensure truthfulness

**Output Schema:**
```json
{
  "contradictions": [],
  "over_claiming_risks": [
    {"claim": "led team of 5", "evidence": "weak", "risk": "medium"}
  ],
  "seniority_match": "aligned",
  "interview_defensibility": 0.88,
  "flagged_items": [
    {"item": "distributed training claim", "reason": "limited evidence", "action": "soften language"}
  ],
  "approval": "safe-to-send"
}
```

---

## Global Constraints

1. **Truthfulness over optimization** - Never fabricate experience
2. **Quantified impact preferred** - Numbers > adjectives
3. **No hallucinated experience** - Stay within evidence boundaries
4. **Optimize for reviewer signal density** - High information per sentence
5. **Interview defensibility** - Every claim must be defensible in interview

---

## System Outputs

**Final Deliverables:**
1. **Tailored Resume** (PDF + Markdown)
   - Reordered, role-specific bullets
   - ATS-optimized keywords
   - Impact-first language

2. **Project Narratives** (1-2 deep stories)
   - STAR format
   - Technical depth
   - Quantified results

3. **Motivation Paragraph** (optional)
   - Role-specific
   - Authentic connection
   - 3-5 sentences

4. **Confidence Report**
   - Fit score
   - Risk assessment
   - Interview defensibility
   - Flagged items

---

## Implementation Notes

### Technical Requirements
- **Framework:** LangChain + LangGraph
- **Agent Orchestration:** DAG-based workflow
- **Structured Outputs:** Pydantic models per agent
- **Memory:** Long-term candidate knowledge persistence
- **Determinism:** Reproducible outputs per job description

### Data Flow
```
Job URL → Job Understanding Agent → Fit & Gap Agent → Parallel:
                                                        ├─ Resume Tailoring Agent
                                                        ├─ Project Storytelling Agent
                                                        └─ Motivation Agent
                                    ↓
                            Consistency & Risk Agent
                                    ↓
                            Final Outputs + Email
```

### Storage
- **Candidate Knowledge:** Persistent (reused across applications)
- **Job Descriptions:** Per-run inputs
- **Tailored Outputs:** Saved with job metadata for tracking

### Extensibility
- Add new agents (e.g., LinkedIn optimization, portfolio generation)
- Plug in different LLMs per agent
- Custom prompts per agent
- Agent output versioning

---

## Next Steps for Implementation

1. **Setup Base Profile**
   - Parse current resume
   - Document projects with STAR format
   - Define skill→evidence mappings

2. **Build Agent Framework**
   - LangGraph orchestrator
   - Pydantic schemas for all agents
   - Agent prompt templates

3. **Implement Agents (Incremental)**
   - Start with Job Understanding + Candidate Knowledge
   - Add Fit & Gap + Resume Tailoring
   - Then Project Storytelling + Motivation
   - Finally Consistency & Risk audit

4. **Integration**
   - Email notification system
   - Job URL → Job Description extraction
   - PDF generation from markdown
   - Application tracking database

5. **Testing & Iteration**
   - Test with 3-5 real job postings
   - Validate interview defensibility
   - Tune agent prompts
   - Optimize for truthfulness

---

## Success Metrics

- **Fit Score Accuracy:** Predicted vs actual interview progression
- **Interview Defensibility:** Claims successfully defended in interviews
- **Time Savings:** Manual tailoring time vs automated (target: <10 min per job)
- **Application Quality:** Recruiter/hiring manager feedback
- **Truthfulness:** Zero fabricated claims detected

---

## Status

**Current Phase:** Architecture defined  
**Next:** Implement base profile setup + agent framework
