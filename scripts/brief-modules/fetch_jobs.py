#!/usr/bin/env python3
"""
fetch_jobs.py - Fetch job application stats from SQLite tracker for morning brief.
Returns JSON: {"active": N, "to_apply": N, "applied": N, "interviewing": N,
               "radar_hits": [{"company": "...", "role": "...", "score": N}]}
"""

import json
import sys
import argparse
from pathlib import Path


def fetch_jobs():
    result = {
        "active": 0,
        "to_apply": 0,
        "applied": 0,
        "interviewing": 0,
        "radar_hits": []
    }

    # Read from SQLite
    db_path = Path.home() / "clawd/job-pipeline/tracker.db"
    if db_path.exists():
        try:
            import sqlite3
            conn = sqlite3.connect(str(db_path))
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()

            # Count by status
            cur.execute("""
                SELECT status, COUNT(*) as cnt
                FROM applications
                WHERE status IN ('to_apply', 'applied', 'interviewing')
                GROUP BY status
            """)
            rows = cur.fetchall()
            for row in rows:
                status = row['status']
                count = row['cnt']
                result[status] = count
                result["active"] += count

            conn.close()
        except Exception as e:
            result["db_error"] = str(e)
    else:
        result["db_note"] = "tracker.db not found"

    # Check radar hits
    radar_path = Path.home() / "clawd/job-pipeline/discovery/last_results.json"
    if radar_path.exists():
        try:
            with open(radar_path) as f:
                radar_data = json.load(f)

            # Handle both list and dict formats
            hits = []
            if isinstance(radar_data, list):
                hits = radar_data
            elif isinstance(radar_data, dict):
                hits = radar_data.get('results', radar_data.get('hits', radar_data.get('jobs', [])))

            radar_hits = []
            for item in hits:
                score = item.get('score', item.get('fit_score', 0))
                if score >= 70:
                    radar_hits.append({
                        "company": item.get('company', 'Unknown'),
                        "role": item.get('role', item.get('title', 'Unknown')),
                        "score": score
                    })

            # Sort by score desc, take top 5
            radar_hits.sort(key=lambda x: x['score'], reverse=True)
            result["radar_hits"] = radar_hits[:5]
        except Exception as e:
            result["radar_error"] = str(e)
    else:
        result["radar_note"] = "last_results.json not found"

    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch job pipeline stats")
    parser.add_argument("--test", action="store_true", help="Print JSON output and exit")
    args = parser.parse_args()

    result = fetch_jobs()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0)
