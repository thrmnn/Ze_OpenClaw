# Mission Control — Improvement Plan

> Audited: 2026-03-19
> Status: Draft — ready for implementation
> Codebase: ~/clawd/mission-control/
> Live: https://mission-control-ruby-zeta.vercel.app/

---

## Audit Summary

### Per-Page Findings

#### `/` — War Room (app/page.tsx)
- **Data**: Live from Convex (agents, tasks, activity, content)
- **Broken**: "Completed Today" counts ALL done tasks, not today's. "Cost Today" shows all-time cost. "Next Event" is hardcoded "No events scheduled" (no events table exists).
- **Missing**: No project health overview. No link from agent status items to agent detail. Activity feed shows nothing when no agents are running.

#### `/agents` — Agent Office (app/agents/page.tsx)
- **Data**: Live from Convex (agents, spawn requests, activity)
- **Broken**: "View Logs" and "Restart" buttons are `alert()` stubs. "Open in VS Code" links to `vscode://pablodelucca.pixel-agents` (dead protocol). Session duration calculated backwards. Agent stats all show 0.
- **Missing**: No live log stream. No real-time heartbeat. No way to see what an agent is actually doing right now. No kill switch.

#### `/tasks` — Kanban Board (app/tasks/page.tsx)
- **Data**: Live from Convex with full CRUD + drag-and-drop
- **Broken**: `PROJECTS` array is hardcoded to 5 projects that don't match the DB. No task deletion from UI.
- **Missing**: No agent assignment UI (field exists in schema but unexposed). No smart priority scoring. No connection between tasks and agent spawning.

#### `/radar` — Position Radar (app/radar/page.tsx)
- **Data**: 100% HARDCODED — 5 static job positions in a `const POSITIONS` array
- **Broken**: Entirely static, no Convex integration. Data is stale demo content.
- **Missing**: Everything. Needs a `positions` table in Convex or should be removed.

#### `/projects` — Projects Portfolio (app/projects/page.tsx)
- **Data**: Live from Convex (seeded projects)
- **Broken**: "Git Status", "Open Vault", "Update Website" buttons have no onClick handlers. Empty state logic bug (`!projects || projects.length === 0 &&` — operator precedence). `ProjectCard` uses `any` type.
- **Missing**: No task count per project. No real git integration. No health score. No deadlines.

#### `/content` — Content Pipeline (app/content/page.tsx)
- **Data**: Live from Convex with create capability
- **Broken**: Nothing critical, but limited functionality.
- **Missing**: No drag-and-drop between stages (tasks page has this, content doesn't). No edit/delete. No detail view.

#### Data Model (convex/schema.ts)
- `tokenUsage` table exists but is NEVER queried anywhere in the frontend.
- `tasks.agentId` exists but is never exposed in UI.
- `projects.gitRepo` status is seeded, never updated from real git.

---

## The 3 Biggest UX Gaps

### Gap 1: "What agents are running RIGHT NOW?"

**Current experience**: Home page shows "Working Agents: 0/7" with all agents idle. Clicking through to /agents shows cards with "Idle" badges and empty activity. "View Logs" does `alert("coming soon")`. There is zero visibility into what any agent is doing.

**Target experience**: Open MC → immediately see a pulsing panel showing "DevBot is editing convex/agents.ts (2m34s, $0.12 so far)" with the last 3 log lines streaming in. A red kill button. A green "all clear" when nothing is running.

**What needs to change**:
- Agents must push heartbeats (status + currentTask + last log lines + token count) via the existing `/api/agent-update` endpoint, called every 30 seconds by the openclaw hook system
- Add `sessionStartedAt` field to agents schema (currently using `lastActive` which is ambiguous)
- Add `lastLogLines` field (array of last 5 strings) to agents schema
- Home page "Agent Status" section should show the current task prominently when status = "working"
- Remove placeholder `alert()` calls from View Logs / Restart buttons — wire them to real Convex data

### Gap 2: "What should the next agent work on?"

**Current experience**: Tasks exist in a kanban board, but there's no queue concept. Tasks don't know about agents. You can't click "assign to DevBot and go". The PROJECTS filter list is hardcoded and doesn't match the actual DB. There's no unified priority that considers due dates.

**Target experience**: A "Next Up" panel on the home page showing the top 5 highest-priority unassigned tasks, sorted by urgency (deadline proximity × priority × project importance). Each has a one-click "Assign Agent" button that opens a modal to pick an agent and spawn it.

**What needs to change**:
- Derive `PROJECTS` list dynamically from the `projects` table instead of hardcoding
- Add urgency scoring: `score = priorityWeight + deadlineProximityBonus + projectPriorityBonus`
- Add a "Next Up" section to the home page showing top-5 unassigned tasks
- Build an "Assign Agent" flow: task card → pick agent → create spawn request → agent starts
- Wire `tasks.agentId` to the UI so you can see which tasks have agents assigned

### Gap 3: "Am I on track across all projects?"

**Current experience**: The /projects page shows cards with static git data ("synced") and non-functional buttons. There's no sense of progress — no task counts, no completion bars, no alerts. The home page has no project overview at all.

**Target experience**: Home page has a "Project Health" grid: each project shows a progress bar (tasks done/total), the last activity timestamp (colored red if stale >3 days), upcoming deadline count, and a health indicator (green/yellow/red). Red projects surface at the top.

**What needs to change**:
- Cross-reference tasks with projects to compute completion percentage per project
- Add a health score: `health = f(tasks_completion_%, days_since_last_activity, deadlines_approaching)`
- Add "Project Health" section to home page with mini status cards
- Add deadline alerts (tasks with dueDate < 48h away show amber, <24h show red)
- Projects page: remove non-functional buttons, add real task counts

---

## Phase 1 — Live Agent Visibility (1-2 days)

### What to build
1. **Agent heartbeat integration**: Ensure the `/api/agent-update` route properly updates agent status, currentTask, and lastActive in real-time when called by openclaw hooks
2. **Schema additions**: Add `sessionStartedAt: v.optional(v.number())` and `lastLogLines: v.optional(v.array(v.string()))` to agents table
3. **Live agent panel on home**: Replace the current simple list with a "Live Agents" panel that shows working agents prominently with elapsed time, current task, and cost
4. **Agent card improvements**: Remove `alert()` stubs, show real log lines, fix session duration calculation

### Files to modify
- `convex/schema.ts` — add sessionStartedAt, lastLogLines fields
- `convex/agents.ts` — update `updateAgentStatus` to set sessionStartedAt when transitioning to "working"
- `app/page.tsx` — redesign Agent Status section into a Live Agents panel
- `app/agents/page.tsx` — fix session duration calc, remove alert() stubs, show log lines
- `app/api/agent-update/route.ts` — ensure it passes through log lines

### Data flow
```
Agent (openclaw hook)
  → POST /api/agent-update { agentId, status, currentTask, logLines }
  → Convex mutation: agents.updateAgentStatus
  → Convex real-time subscription pushes to UI
  → Home page & Agents page re-render with live data
```

---

## Phase 2 — Intelligent Backlog (2-3 days)

### What to build
1. **Dynamic project list**: Replace hardcoded `PROJECTS` in tasks page with a Convex query to the projects table
2. **Urgency scoring system**: Convex query that returns tasks sorted by computed urgency score
3. **"Next Up" panel on home page**: Shows top 5 unassigned tasks by urgency
4. **Agent assignment flow**: Modal on task cards to pick an agent → creates spawn request → agent picks up work
5. **Task-agent linkage UI**: Show agent avatar on task cards when assigned, filter tasks by agent

### Files to modify
- `convex/tasks.ts` — add `getTopUnassignedTasks` query with urgency scoring
- `convex/projects.ts` — add `listProjectNames` query (just names for dropdown)
- `app/tasks/page.tsx` — replace hardcoded PROJECTS, add agent assignment button, add delete button
- `app/page.tsx` — add "Next Up" section
- New: `components/AssignAgentModal.tsx` — agent picker modal

### Priority scoring algorithm
```
urgencyScore =
  (priority === "high" ? 30 : priority === "medium" ? 20 : 10)
  + (dueDate ? max(0, 30 - daysTilDue * 3) : 0)   // up to 30 points for imminent deadlines
  + (projectPriority === "high" ? 15 : projectPriority === "medium" ? 10 : 5)
```

### Auto-assignment flow
```
User clicks "Assign" on task card
  → AssignAgentModal opens, shows idle agents
  → User picks agent, clicks "Go"
  → Creates spawnRequest + updates task.agentId
  → Agent page shows pending request for approval
  → On approval, agent begins work
```

---

## Phase 3 — Project Health Dashboard (1-2 days)

### What to build
1. **Project health query**: Convex query that joins projects with tasks to compute per-project stats (total tasks, done tasks, overdue tasks, last activity)
2. **Health score algorithm**: Green (>70% done, no overdue), Yellow (50-70% done or 1 overdue), Red (<50% done or >1 overdue or stale >3 days)
3. **Home page project health grid**: Mini cards with progress bar, health dot, deadline count
4. **Projects page upgrade**: Show task counts, real progress, remove dead buttons
5. **Alert banner**: Show on home page when any project is red

### Files to modify
- `convex/projects.ts` — add `getProjectHealth` query that joins with tasks
- `app/page.tsx` — add "Project Health" section between stats and activity feed
- `app/projects/page.tsx` — integrate task data, fix empty state bug, remove dead buttons, add progress bars

### Health calculation
```
For each project:
  tasksDone = tasks.filter(t => t.project === p.name && t.status === "done").length
  tasksTotal = tasks.filter(t => t.project === p.name).length
  overdue = tasks.filter(t => t.project === p.name && t.dueDate < now && t.status !== "done").length
  daysSinceActivity = (now - p.lastUpdated) / 86400000

  health = "green" if completion > 70% AND overdue === 0 AND daysSinceActivity < 3
  health = "red" if completion < 30% OR overdue > 1 OR daysSinceActivity > 7
  health = "yellow" otherwise
```

---

## Phase 4 — Agent Efficiency Metrics (ongoing)

### What to build
1. **Token usage tracking**: Wire the existing `tokenUsage` table to the frontend. Log every agent session's token usage.
2. **Per-agent efficiency cards**: On the agents page, show tokens/task, cost/task, avg completion time trend
3. **Daily cost chart**: Simple bar chart on home page showing cost per day over last 7 days
4. **Parallelism metric**: Show "Agents running: 2/7 (28% utilization)" — how many agents COULD be running vs ARE running
5. **Session history**: Per-agent list of past sessions with duration, task, tokens, cost, success/failure

### Files to modify
- `convex/agents.ts` — log to tokenUsage table on every `updateAgentStats` call
- `convex/tokenUsage.ts` (new) — queries for daily totals, per-agent totals, trends
- `app/page.tsx` — add daily cost mini chart
- `app/agents/page.tsx` — add efficiency metrics to agent cards, add session history expandable section

### Key metrics
- **Token efficiency**: tokens per completed task (lower is better)
- **Cost per task**: total cost / tasks completed
- **Success rate**: tasks completed / tasks attempted
- **Parallelism**: max(agents working at same time) / total agents
- **Utilization**: total agent-minutes working / total available agent-minutes

---

## Quick Wins (applied in this audit)

1. **Fix "Completed Today" label** — it counts ALL done tasks, not today's. Changed label to "Total Completed" for accuracy.
2. **Fix empty state bug in Projects** — `!projects || projects.length === 0 &&` has operator precedence issue. Added parentheses.
3. **Fix "Cost Today" label** — shows all-time cost, not today's. Changed to "Total Cost".
4. **Remove dead "Open in VS Code" link** from agents page header (links to non-existent `vscode://pablodelucca.pixel-agents`).
5. **Fix stale version indicator** — updated from v0.2.0 to v0.3.0.

---

## Architecture Notes

### Current Stack
- **Frontend**: Next.js 14 (App Router) + Tailwind CSS
- **Backend**: Convex (real-time DB + serverless functions)
- **Hosting**: Vercel
- **Agent integration**: REST API routes that call Convex mutations

### Key Convex Tables
| Table | Used in UI | Notes |
|-------|-----------|-------|
| agents | Yes | Core — needs heartbeat fields |
| spawnRequests | Yes | Approval workflow works |
| activityLog | Yes | Activity feed on home + agents |
| content | Yes | Content pipeline CRUD |
| projects | Yes | Needs health metrics |
| tasks | Yes | Needs dynamic project list |
| tokenUsage | **NO** | Table exists, never queried |

### API Routes (13 total, many are test/debug)
Production routes:
- `/api/agent-update` — update agent status
- `/api/activity` — log activity
- `/api/spawn-request` — create spawn request
- `/api/tasks` — task CRUD
- `/api/status` — health check

Debug/test routes (can be removed):
- `/api/test-direct`, `/api/test-double-mutation`, `/api/test-single-mutation`
- `/api/create-ze`, `/api/force-create-ze`
- `/api/agent-update-v2`, `/api/agent-update-direct`
- `/api/pixel-agents`
