#!/usr/bin/env python3
"""Test Calendar access"""

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from datetime import datetime, timedelta

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

creds = Credentials.from_authorized_user_file(TOKEN_FILE)
service = build('calendar', 'v3', credentials=creds)

# Get events for next 7 days
now = datetime.utcnow().isoformat() + 'Z'
week = (datetime.utcnow() + timedelta(days=7)).isoformat() + 'Z'

print("📅 Calendar Access Test\n")

events_result = service.events().list(
    calendarId='primary',
    timeMin=now,
    timeMax=week,
    maxResults=5,
    singleEvents=True,
    orderBy='startTime'
).execute()

events = events_result.get('items', [])

if not events:
    print('✅ Calendar access OK - No events in next 7 days')
else:
    print(f'✅ Calendar access OK - Found {len(events)} events:\n')
    for event in events:
        start = event['start'].get('dateTime', event['start'].get('date'))
        print(f"  • {event.get('summary', 'No title')} - {start}")
