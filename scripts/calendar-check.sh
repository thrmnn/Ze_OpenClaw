#!/bin/bash
# Calendar check - shows upcoming events

cd ~/clawd
source venv-google/bin/activate 2>/dev/null

python3 << 'EOF'
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from datetime import datetime, timedelta
import pytz

# Load credentials
token_file = Path.home() / "clawd/credentials/google-tokens.json"
creds = Credentials.from_authorized_user_file(str(token_file))

if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    with open(token_file, 'w') as f:
        f.write(creds.to_json())

# Get calendar events
service = build('calendar', 'v3', credentials=creds)

# Get events for next 24 hours
tz = pytz.timezone('America/Sao_Paulo')
now = datetime.now(tz)
tomorrow = now + timedelta(days=1)

events_result = service.events().list(
    calendarId='primary',
    timeMin=now.isoformat(),
    timeMax=tomorrow.isoformat(),
    maxResults=10,
    singleEvents=True,
    orderBy='startTime'
).execute()

events = events_result.get('items', [])

if not events:
    print("📅 No events in the next 24 hours")
else:
    print(f"📅 Upcoming events ({len(events)}):\n")
    for event in events:
        start = event['start'].get('dateTime', event['start'].get('date'))
        start_dt = datetime.fromisoformat(start.replace('Z', '+00:00'))
        
        # Calculate time until event
        delta = start_dt - now
        hours = int(delta.total_seconds() // 3600)
        minutes = int((delta.total_seconds() % 3600) // 60)
        
        if hours == 0:
            time_str = f"in {minutes} min"
        elif hours < 24:
            time_str = f"in {hours}h {minutes}m"
        else:
            time_str = start_dt.strftime("%a %H:%M")
        
        print(f"• {event['summary']} → {time_str}")

EOF
