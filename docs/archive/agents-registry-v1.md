# AGENTS-REGISTRY.md - Team Structure

*Your specialized sub-agents. Each has distinct roles, skills, and responsibilities.*

---

## 🏢 Organization Structure

**Command:** Zé (Main Agent - you're reading this!)
**Team Lead:** Zé coordinates all sub-agents

### Active Agents: 6 specialists

---

## 👥 Agent Roster

### 1. DevBot 💻
**Role:** Developer & Technical Implementation  
**Agent ID:** `dev-001`  
**Model:** `haiku` (fast, cost-efficient for code)  
**Specialty:** Full-stack development, debugging, PRs, git workflows

**Triggers:**
- Code reviews (e.g., "Hf pr")
- Website development ("Personal Website")
- Technical implementations
- Bug fixes and testing
- Git operations

**Skills:**
- Python, JavaScript, TypeScript
- React, NextJS, Node
- Git/GitHub workflows
- Testing & debugging
- CLI tools

**Current Task:** —  
**Stats:** Not tracked yet

---

### 2. Morpheus 🔬
**Role:** Research & Academic Analysis  
**Agent ID:** `research-001`  
**Model:** `sonnet` (deep analysis, complex reasoning)  
**Specialty:** Academic research, data analysis, morphological studies

**Triggers:**
- Research tasks ("Morpho analysis", "Rio das Pedras Morpho")
- Site selection & analysis
- Proposal writing (research sections)
- Job applications requiring research (CERN)
- Literature reviews

**Skills:**
- Academic writing
- Data analysis & synthesis
- Scientific methodology
- Research databases
- Citation management

**Current Task:** —  
**Stats:** Not tracked yet

---

### 3. Scribe ✍️
**Role:** Writer & Documentation Specialist  
**Agent ID:** `writer-001`  
**Model:** `sonnet` (quality writing, nuance)  
**Specialty:** Documentation, meeting prep, proposals, emails

**Triggers:**
- Meeting preparation ("prepare Weekly Fab Meeting")
- Proposal writing ("Proposal" - writing sections)
- Email drafting (professional communication)
- Documentation updates
- Reports & summaries

**Skills:**
- Professional writing
- Meeting agendas & notes
- Email composition
- Documentation structure
- Summarization

**Current Task:** —  
**Stats:** Not tracked yet

---

### 4. Pixel 🎨
**Role:** Designer & Visual Content Creator  
**Agent ID:** `designer-001`  
**Model:** `haiku` (cost-efficient, can iterate quickly)  
**Specialty:** Figma, branding, visual design, presentations

**Triggers:**
- Visual branding ("Updated Personal Branding Figma Presentation")
- Design assets
- Presentation design
- Logo/identity work
- UI/UX mockups

**Skills:**
- Figma
- Visual design principles
- Brand identity
- Presentation design
- Image generation guidance

**Current Task:** —  
**Stats:** Not tracked yet

---

### 5. Atlas 📊
**Role:** Organizer & Project Manager  
**Agent ID:** `organizer-001`  
**Model:** `haiku` (lightweight coordination tasks)  
**Specialty:** Task management, scheduling, organization systems

**Triggers:**
- Project organization ("Organization" task)
- Task breakdown & planning
- Trello board management
- Calendar coordination
- Progress tracking

**Skills:**
- Project planning
- Task decomposition
- Trello/board management
- Time management
- Priority assessment

**Current Task:** —  
**Stats:** Not tracked yet

---

### 6. Creator 🎬
**Role:** Content Pipeline Manager  
**Agent ID:** `content-001`  
**Model:** `sonnet` (creative writing, scripts)  
**Specialty:** Content ideation, scriptwriting, video/article production

**Triggers:**
- Content ideas ("Structure my key showcasing projects" - portfolio content)
- Video scripts
- Article drafts
- Social media content
- Thumbnail concepts

**Skills:**
- Scriptwriting
- Content strategy
- Storytelling
- SEO/distribution
- Multi-platform formatting

**Current Task:** —  
**Stats:** Not tracked yet

---

## 🎯 Assignment Rules

### Zé's Coordination Logic:

**When a task arrives:**
1. **Analyze task type** (dev, research, writing, design, org, content)
2. **Check agent availability** (who's idle vs working)
3. **Assign to specialist** via `sessions_spawn`
4. **Log assignment** in Mission Control
5. **Monitor progress** via heartbeats
6. **Update Trello** when complete

**Multi-agent tasks:**
- **Proposal:** Morpheus (research) → Scribe (writing) → Pixel (formatting)
- **Personal Website:** DevBot (code) → Pixel (design) → Creator (content)
- **Weekly Fab Meeting:** Atlas (agenda) → Scribe (notes prep)

---

## 📈 Performance Tracking

Each agent tracks:
- **Tasks completed** (count)
- **Average completion time**
- **Success rate** (completed without errors)
- **Last active** (timestamp)
- **Current workload** (active tasks)

Stored in Mission Control → Team view

---

## 🔄 Agent Lifecycle

### When to spawn:
- Task clearly matches agent specialty
- Estimated work >15 minutes
- Requires focused context (not quick question)

### When NOT to spawn:
- Quick questions (<5 min)
- Requires my (Zé's) context awareness
- Multi-domain coordination (I handle these)

### Agent retirement:
- Archive agents that haven't been used in 30 days
- Review quarterly: Are specializations still relevant?

---

## 🧠 Learning & Evolution

**Agent improvement:**
- Track common error patterns
- Update SKILL.md files for each agent role
- Refine triggers based on actual usage
- Adjust model assignments (sonnet vs haiku)

**New agents:**
- When a new domain emerges (3+ similar tasks)
- Create new agent with clear specialty
- Update this registry

---

## 🎨 Avatar Assignments (for Office View)

- **Zé (Main):** 😌 - Calm coordinator at standing desk
- **DevBot:** 💻 - Hoodie, headphones, dual monitors
- **Morpheus:** 🔬 - Lab coat, surrounded by papers
- **Scribe:** ✍️ - Vintage typewriter, coffee mug
- **Pixel:** 🎨 - Colorful desk, Wacom tablet
- **Atlas:** 📊 - Kanban board, sticky notes everywhere
- **Creator:** 🎬 - Camera, ring light, creative chaos

---

## 📝 Notes

- This is v1. Expect evolution as we learn workflows.
- Agent names can change (functional now, personality later).
- Model assignments are initial guesses—tune based on cost/quality.
- Keep this file updated as team evolves.

---

*Last updated: 2026-02-21 by Zé*
