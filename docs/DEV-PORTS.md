# DEV-PORTS.md — Local Port Reference

> Quick reference for all localhost ports when developing across projects.
> Last updated: 2026-03-20

---

## 🎙️ EPIRBE Web Radio
`~/sidequests/EPIRBE/` — start: `bash scripts/dev.sh` or `docker-compose up`

| Port | Service | URL |
|------|---------|-----|
| **3000** | Frontend (React/Vite) | http://localhost:3000 |
| **8080** | Backend (FastAPI) | http://localhost:8080 |
| **8005** | Icecast stream | http://localhost:8005 |
| **1234** | Liquidsoap telnet | telnet localhost 1234 |

---

## 🤖 AI Agency MVP
`~/projects/ai-agency/mvp/` — start: `docker-compose up -d && streamlit run app.py`

| Port | Service | URL |
|------|---------|-----|
| **8000** | FastAPI backend | http://localhost:8000 |
| **8501** | Streamlit UI | http://localhost:8501 |
| **6333** | Qdrant REST API | http://localhost:6333 |
| **6334** | Qdrant gRPC | grpc://localhost:6334 |

---

## 🎛️ Mission Control Dashboard
`~/projects/mission-control/` — start: `npm run dev`

| Port | Service | URL |
|------|---------|-----|
| **3000** | Next.js dev server | http://localhost:3000 |

> ⚠️ Conflicts with EPIRBE frontend (both use 3000). Don't run both at the same time, or change EPIRBE to 3001.

---

## 📈 Trading Bot
`~/projects/trading-bot/` — Python scripts, no persistent server

| Port | Service | Notes |
|------|---------|-------|
| *(no server)* | CLI/scripts only | Run: `python main.py` |

---

## 🔍 Job Pipeline
`~/projects/job-pipeline/` — conda env: `job-pipeline`

| Port | Service | Notes |
|------|---------|-------|
| *(no server)* | CLI only | Run: `conda run -n job-pipeline python process_queue.py` |

---

## 🗄️ Shared Infrastructure (Docker)

| Port | Service | Used by |
|------|---------|---------|
| **6333** | Qdrant REST | AI Agency |
| **6334** | Qdrant gRPC | AI Agency |

---

## 🚀 Quick Start by Project

```bash
# EPIRBE Web Radio
cd ~/sidequests/EPIRBE && docker-compose up
# → Frontend: http://localhost:3000
# → Backend:  http://localhost:8080

# AI Agency
cd ~/projects/ai-agency/mvp
docker-compose up -d          # starts Qdrant on 6333/6334 + backend on 8000 + Streamlit on 8501
source .venv/bin/activate
streamlit run app.py          # if not using docker for frontend
# → Streamlit: http://localhost:8501
# → API docs:  http://localhost:8000/docs

# Mission Control
cd ~/projects/mission-control && npm run dev
# → Dashboard: http://localhost:3000
```

---

## ⚠️ Port Conflicts to Watch

| Conflict | Projects | Fix |
|----------|---------|-----|
| Port 3000 | EPIRBE frontend + Mission Control | Don't run simultaneously, or change EPIRBE to `--port 3001` |
| Port 8000 | EPIRBE backend + AI Agency backend | Don't run simultaneously |
