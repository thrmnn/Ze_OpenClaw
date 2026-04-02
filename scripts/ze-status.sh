#!/usr/bin/env bash
# ze-status.sh — One-glance system health summary for Zé
set -euo pipefail

BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"

now=$(date +%s)

hr() { printf '%*s\n' 50 '' | tr ' ' '─'; }

# ──────────────────────────────────────────────────
# 💓 Heartbeat Freshness
# ──────────────────────────────────────────────────
echo -e "\n${BOLD}💓 Heartbeat Freshness${RESET}"
hr

HB_FILE="$HOME/clawd/memory/heartbeat-state.json"
if [[ -f "$HB_FILE" ]]; then
    python3 -c "
import json, time
with open('$HB_FILE') as f:
    data = json.load(f)
now = time.time()
checks = data.get('lastChecks', {})
for name, ts in sorted(checks.items()):
    age_h = (now - ts) / 3600
    if age_h < 6:
        color = '\033[32m'   # green
        status = 'OK'
    elif age_h < 24:
        color = '\033[33m'   # yellow
        status = 'STALE'
    else:
        color = '\033[31m'   # red
        status = 'OLD'
    print(f'  {color}{status:5s}\033[0m  {name:20s}  ({age_h:.0f}h ago)')
"
else
    echo -e "  ${RED}heartbeat-state.json not found${RESET}"
fi

# ──────────────────────────────────────────────────
# ⏰ Active Crons
# ──────────────────────────────────────────────────
echo -e "\n${BOLD}⏰ Active Crons${RESET}"
hr

if command -v openclaw &>/dev/null; then
    openclaw cron list --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
jobs = data.get('jobs', data) if isinstance(data, dict) else data
enabled = [j for j in jobs if j.get('enabled', True)]
print(f'  {len(enabled)} active cron jobs:')
for j in enabled:
    name = j.get('name', '?')
    status = j.get('state', {}).get('lastStatus', j.get('status', '-'))
    sched = j.get('schedule', {}).get('expr', '?')
    print(f'    {name:40s}  [{sched}]  {status}')
" 2>/dev/null || echo "  (could not parse cron list)"
else
    echo -e "  ${RED}openclaw not found${RESET}"
fi

# ──────────────────────────────────────────────────
# 📦 Git Status Across Projects
# ──────────────────────────────────────────────────
echo -e "\n${BOLD}📦 Git Status (last commit)${RESET}"
hr

for project in clawd job-pipeline website position-radar mission-control; do
    dir=""
    # resolve actual path (some are symlinks in ~/projects)
    if [[ -d "$HOME/clawd" && "$project" == "clawd" ]]; then
        dir="$HOME/clawd"
    elif [[ -d "$HOME/projects/$project" ]]; then
        dir="$HOME/projects/$project"
    elif [[ -d "$HOME/$project" ]]; then
        dir="$HOME/$project"
    fi

    if [[ -n "$dir" && -d "$dir/.git" ]]; then
        last_commit=$(git -C "$dir" log -1 --format='%cr — %s' 2>/dev/null || echo "?")
        dirty=""
        if [[ -n $(git -C "$dir" status --porcelain 2>/dev/null) ]]; then
            dirty=" ${YELLOW}[dirty]${RESET}"
        fi
        printf "  %-20s %s%b\n" "$project" "$last_commit" "$dirty"
    else
        printf "  %-20s ${DIM}(not found or no git)${RESET}\n" "$project"
    fi
done

# ──────────────────────────────────────────────────
# 🧠 QMD Status
# ──────────────────────────────────────────────────
echo -e "\n${BOLD}🧠 QMD Status${RESET}"
hr

if command -v qmd &>/dev/null; then
    qmd status 2>&1 | head -5 | sed 's/^/  /'
else
    echo -e "  ${DIM}qmd not installed${RESET}"
fi

# ──────────────────────────────────────────────────
# 💼 Active Job Applications
# ──────────────────────────────────────────────────
echo -e "\n${BOLD}💼 Job Applications${RESET}"
hr

TRACKER_DB="$HOME/clawd/job-pipeline/tracker.db"
if [[ -f "$TRACKER_DB" ]]; then
    python3 -c "
import sqlite3
con = sqlite3.connect('$TRACKER_DB')
cur = con.cursor()
active = cur.execute(\"SELECT COUNT(*) FROM applications WHERE status NOT IN ('rejected','withdrawn','closed')\").fetchone()[0]
total = cur.execute('SELECT COUNT(*) FROM applications').fetchone()[0]
discovered = cur.execute('SELECT COUNT(*) FROM discovered_jobs').fetchone()[0]
print(f'  Active: {active}  |  Total applied: {total}  |  Discovered: {discovered}')
con.close()
" 2>/dev/null || echo "  (could not query tracker.db)"
else
    echo -e "  ${DIM}tracker.db not found${RESET}"
fi

echo -e "\n${DIM}Generated $(date '+%Y-%m-%d %H:%M:%S')${RESET}\n"
