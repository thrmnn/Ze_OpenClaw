#!/usr/bin/env python3
"""
fetch_calendar.py - Fetch today's Google Calendar events for morning brief.
Returns JSON: {"events": [{"time": "09:00", "title": "...", "duration_min": 60}], "count": N}
"""

import json
import sys
import argparse
from pathlib import Path
from datetime import datetime, timedelta

def fetch_calendar():
    try:
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
        from googleapiclient.discovery import build
        import pytz

        token_file = Path.home() / "clawd/credentials/google-tokens.json"
        if not token_file.exists():
            return {"events": [], "count": 0, "error": "credentials not found"}

        creds = Credentials.from_authorized_user_file(str(token_file))

        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_file, 'w') as f:
                f.write(creds.to_json())

        service = build('calendar', 'v3', credentials=creds)

        tz = pytz.timezone('America/Sao_Paulo')
        now = datetime.now(tz)
        # Today: midnight → midnight
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timedelta(days=1)

        events_result = service.events().list(
            calendarId='primary',
            timeMin=today_start.isoformat(),
            timeMax=today_end.isoformat(),
            maxResults=20,
            singleEvents=True,
            orderBy='startTime'
        ).execute()

        raw_events = events_result.get('items', [])
        events = []

        for event in raw_events:
            title = event.get('summary', '(no title)')
            start_raw = event['start'].get('dateTime', event['start'].get('date'))
            end_raw = event['end'].get('dateTime', event['end'].get('date'))

            # All-day events
            if 'T' not in start_raw:
                events.append({
                    "time": "all-day",
                    "title": title,
                    "duration_min": 1440
                })
                continue

            start_dt = datetime.fromisoformat(start_raw).astimezone(tz)
            end_dt = datetime.fromisoformat(end_raw).astimezone(tz)
            duration_min = int((end_dt - start_dt).total_seconds() / 60)

            events.append({
                "time": start_dt.strftime("%H:%M"),
                "title": title,
                "duration_min": duration_min
            })

        return {"events": events, "count": len(events)}

    except Exception as e:
        return {"events": [], "count": 0, "error": str(e)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch today's calendar events")
    parser.add_argument("--test", action="store_true", help="Print JSON output and exit")
    args = parser.parse_args()

    result = fetch_calendar()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0)
