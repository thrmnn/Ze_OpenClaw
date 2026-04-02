# Project — Mission Control Dashboard

> Extracted from MEMORY.md on 2026-04-02

## URLs & Access
- Live: https://mission-control-ruby-zeta.vercel.app/
- Tasks/Kanban: https://mission-control-ruby-zeta.vercel.app/tasks
- Codebase: `~/clawd/mission-control/`
- Convex backend: `prod:usable-whale-844`

## Pages
- `/` — war room (live agent detection, project board, auto-refresh 30s)
- `/tasks` — Kanban (replaces Trello)
- `/agents` — live activity + pixel-agents VS Code deep link
- `/memory` — search
- `/radar` — Position Radar table
- `/api/status` — JSON status endpoint
- `/api/pixel-agents` — JSON for VS Code extension

## Deploy
- Auto-deploys from Vercel on git push to main
- To redeploy after local changes: push `~/clawd/mission-control` to its GitHub remote
- Deployed via `origin/master`

## Known Issues
- Write mutations via API unreliable (task updates inconsistent)
- `/api/status` working as of 2026-03-19
