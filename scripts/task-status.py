#!/usr/bin/env python3
"""Pretty-print the Zé task ledger."""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LEDGER_FILE = Path.home() / "clawd" / "memory" / "active-tasks.json"

def time_ago(iso_str):
    """Return human-readable time delta from ISO string to now."""
    if not iso_str:
        return "unknown"
    dt = datetime.fromisoformat(iso_str)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    delta = datetime.now(timezone.utc) - dt
    total_sec = int(delta.total_seconds())
    if total_sec < 0:
        return "just now"
    if total_sec < 60:
        return f"{total_sec}s ago"
    mins = total_sec // 60
    if mins < 60:
        return f"{mins} min ago"
    hours = mins // 60
    if hours < 24:
        return f"{hours}h {mins % 60}m ago"
    days = hours // 24
    return f"{days}d ago"


def main():
    if not LEDGER_FILE.exists():
        print("No task ledger found.")
        sys.exit(1)

    ledger = json.loads(LEDGER_FILE.read_text())
    tasks = ledger.get("tasks", [])
    now = datetime.now(timezone.utc)
    header_time = now.strftime("%Y-%m-%d %H:%M")

    running = [t for t in tasks if t["status"] == "running"]
    done = [t for t in tasks if t["status"] == "done"]
    failed = [t for t in tasks if t["status"] == "failed"]
    cancelled = [t for t in tasks if t["status"] == "cancelled"]

    bar = "\u2550" * 43
    print(f"\n{bar}")
    print(f"  Z\u00e9 Task Ledger \u2014 {header_time}")
    print(f"{bar}")

    # Running
    print(f"\nRUNNING ({len(running)})")
    if running:
        for t in running:
            print(f"  \u25b6 [{t['id']}] {t['label']} \u2014 {t['summary']}")
            print(f"    Started: {time_ago(t.get('started_at'))}")
            if t.get("session_id"):
                print(f"    Session: {t['session_id'][:12]}...")
    else:
        print("  (none)")

    # Done
    print(f"\nDONE ({len(done)})")
    if done:
        for t in done:
            result = t.get("result") or "no details"
            print(f"  \u2713 [{t['id']}] {t['label']} \u2014 {result}")
    else:
        print("  (none)")

    # Failed
    print(f"\nFAILED ({len(failed)})")
    if failed:
        for t in failed:
            error = t.get("error") or "unknown error"
            print(f"  \u2717 [{t['id']}] {t['label']} \u2014 {error}")
    else:
        print("  (none)")

    # Cancelled
    if cancelled:
        print(f"\nCANCELLED ({len(cancelled)})")
        for t in cancelled:
            print(f"  \u2014 [{t['id']}] {t['label']}")

    print(f"\n{bar}\n")


if __name__ == "__main__":
    main()
