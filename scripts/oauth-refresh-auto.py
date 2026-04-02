#!/usr/bin/env python3
"""
Automatic OAuth refresh using local server
This will open a browser window automatically
"""

from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/calendar.readonly'
]

client_file = Path.home() / "clawd/credentials/google-oauth-client.json"
token_file = Path.home() / "clawd/credentials/google-tokens.json"

print("🔄 Starting OAuth flow...")
print("📌 A browser window will open")
print("📌 Sign in and grant permissions")
print("📌 The window will close automatically when done\n")

# This uses run_local_server which handles everything
flow = InstalledAppFlow.from_client_secrets_file(str(client_file), SCOPES)
creds = flow.run_local_server(port=0)  # port=0 means pick any available port

# Save credentials
with open(token_file, 'w') as f:
    f.write(creds.to_json())

print(f"\n✅ Tokens saved to: {token_file}")

# Test
from googleapiclient.discovery import build
service = build('gmail', 'v1', credentials=creds)
profile = service.users().getProfile(userId='me').execute()
print(f"✅ Gmail access verified: {profile['emailAddress']}")
print("\n🎉 OAuth refresh complete!")
