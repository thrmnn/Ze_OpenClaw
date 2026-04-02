#!/usr/bin/env python3
"""
Google OAuth re-auth via local server (localhost redirect).
Prints the auth URL — user opens it, Google redirects to localhost,
server catches the code and exchanges it automatically.
"""

import os
import sys
import json
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
]

CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def main():
    flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, scopes=SCOPES)
    
    # run_local_server starts a local HTTP server and waits for the callback
    # open_browser=False so we print the URL instead of trying to open it
    creds = flow.run_local_server(
        port=8080,
        open_browser=False,
        prompt='consent',
        access_type='offline',
        authorization_prompt_message="\n🔐 Open this URL in your browser:\n\n{url}\n\nWaiting for authorization...\n"
    )

    # Save tokens
    with open(TOKEN_FILE, 'w') as f:
        f.write(creds.to_json())

    print(f"\n✅ Tokens saved to {TOKEN_FILE}")
    print(f"   Scopes: {len(creds.scopes)} authorized")

if __name__ == '__main__':
    main()
