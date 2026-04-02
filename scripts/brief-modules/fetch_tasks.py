#!/usr/bin/env python3
"""
fetch_tasks.py - Fetch top tasks from Mission Control API for morning brief.
Returns JSON: {"tasks": [{"title": "...", "project": "...", "status": "..."}]}
If API fails: {"tasks": [], "error": "MC unreachable"}
"""

import json
import sys
import argparse

MC_API_URL = "https://mission-control-ruby-zeta.vercel.app/api/status"

STATUS_PRIORITY = {
    "in_progress": 0,
    "in-progress": 0,
    "now": 0,
    "active": 1,
    "next": 2,
    "high": 2,
    "waiting": 3,
    "todo": 3,
    "pending": 3,
    "done": 99,
    "complete": 99,
    "completed": 99,
}


def status_rank(task):
    """Lower rank = higher priority."""
    status = str(task.get('status', '')).lower()
    priority = str(task.get('priority', '')).lower()
    rank = STATUS_PRIORITY.get(status, 50)
    # Also consider priority field
    if priority in ('high', 'urgent', 'critical'):
        rank = min(rank, 2)
    return rank


def extract_tasks(data):
    """Extract tasks from MC API response in various formats."""
    tasks = []

    # Direct tasks array
    if isinstance(data, list):
        tasks = data
    elif isinstance(data, dict):
        # Try common keys
        for key in ('tasks', 'todos', 'items', 'work'):
            if key in data and isinstance(data[key], list):
                tasks = data[key]
                break

        # Nested: data.tasks.byStatus or similar
        if not tasks and 'tasks' in data and isinstance(data['tasks'], dict):
            task_obj = data['tasks']
            # Flatten all statuses
            for k, v in task_obj.items():
                if isinstance(v, list):
                    for item in v:
                        if isinstance(item, dict):
                            item.setdefault('status', k)
                            tasks.append(item)

    # Filter out done/completed
    active_tasks = [t for t in tasks if status_rank(t) < 90]

    # Sort by priority
    active_tasks.sort(key=status_rank)

    result = []
    for t in active_tasks[:3]:
        result.append({
            "title": t.get('title', t.get('name', t.get('summary', 'Unknown'))),
            "project": t.get('project', t.get('category', t.get('tag', ''))),
            "status": t.get('status', 'unknown')
        })

    return result


def fetch_tasks():
    try:
        import urllib.request
        import urllib.error

        req = urllib.request.Request(
            MC_API_URL,
            headers={"User-Agent": "MorningBrief/1.0", "Accept": "application/json"}
        )

        with urllib.request.urlopen(req, timeout=10) as response:
            raw = response.read().decode('utf-8')
            data = json.loads(raw)

        tasks = extract_tasks(data)

        # If no structured tasks found, surface recentActivity as context
        if not tasks and isinstance(data, dict) and 'recentActivity' in data:
            activity = data['recentActivity']
            for item in activity[:3]:
                tasks.append({
                    "title": item.get('message', item.get('type', 'Unknown')),
                    "project": item.get('type', ''),
                    "status": "recent"
                })

        return {"tasks": tasks}

    except Exception as e:
        return {"tasks": [], "error": "MC unreachable"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch tasks from Mission Control")
    parser.add_argument("--test", action="store_true", help="Print JSON output and exit")
    args = parser.parse_args()

    result = fetch_tasks()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0)
