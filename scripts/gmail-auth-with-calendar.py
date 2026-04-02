#!/usr/bin/env python3
"""
Gmail + Drive + Calendar OAuth
"""

from google_auth_oauthlib.flow import Flow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/calendar.readonly',      # NEW
    'https://www.googleapis.com/auth/calendar.events'         # NEW
]

CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'

flow = Flow.from_client_secrets_file(
    CREDS_FILE,
    scopes=SCOPES,
    redirect_uri='urn:ietf:wg:oauth:2.0:oob'
)

auth_url, _ = flow.authorization_url(prompt='consent')

print("🔐 OAuth URL (with Calendar):")
print("=" * 80)
print(auth_url)
print("=" * 80)
print("\nSteps:")
print("1. Open URL → Login with zeclawd@gmail.com")
print("2. Authorize Calendar permissions")
print("3. Send me the code")
