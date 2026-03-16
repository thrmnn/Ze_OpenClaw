#!/usr/bin/env python3
"""
Exchange OAuth code - WITH CALENDAR
"""

import sys
from google_auth_oauthlib.flow import Flow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events'
]

CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

if len(sys.argv) < 2:
    print("Usage: python3 exchange-oauth-code-calendar.py <code>")
    sys.exit(1)

code = sys.argv[1]

flow = Flow.from_client_secrets_file(
    CREDS_FILE,
    scopes=SCOPES,
    redirect_uri='urn:ietf:wg:oauth:2.0:oob'
)

print("⏳ Exchanging code...")
flow.fetch_token(code=code)
creds = flow.credentials

with open(TOKEN_FILE, 'w') as token:
    token.write(creds.to_json())

print(f"✅ Tokens saved: {TOKEN_FILE}")
print("\nScopes granted:")
for scope in creds.scopes:
    print(f"  • {scope}")
