#!/usr/bin/env python3
"""
Full Google OAuth re-authorization flow.
Use this when the refresh_token has been revoked (invalid_grant error).

Starts a local HTTP server on port 8080, prints an auth URL.
Open the URL in a browser, grant access, and the script saves fresh tokens.

Usage:
    ~/clawd/venv-google/bin/python3 ~/clawd/scripts/google-oauth-reauth.py
"""

import json
import sys
from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events',
]

CREDS_FILE = Path.home() / 'clawd/credentials/google-oauth-client.json'
TOKEN_FILE = Path.home() / 'clawd/credentials/google-tokens.json'


def main():
    if not CREDS_FILE.exists():
        print(f'ERROR: client credentials not found at {CREDS_FILE}')
        sys.exit(1)

    print('=== Google OAuth Re-Authorization ===')
    print()
    print('A browser URL will be printed below.')
    print('Open it, sign in, grant access, then return here.')
    print()

    flow = InstalledAppFlow.from_client_secrets_file(str(CREDS_FILE), scopes=SCOPES)

    creds = flow.run_local_server(
        port=8080,
        open_browser=False,
        prompt='consent',           # force consent screen to get refresh_token
        access_type='offline',      # required for refresh_token
    )

    # Save in the same format the MCP server / scripts expect
    token_data = json.loads(creds.to_json())
    TOKEN_FILE.write_text(json.dumps(token_data, indent=2))

    print()
    print(f'Tokens saved to {TOKEN_FILE}')
    print(f'  scopes: {len(creds.scopes)} authorized')
    print(f'  refresh_token present: {bool(creds.refresh_token)}')

    # Quick verification
    try:
        from googleapiclient.discovery import build
        service = build('gmail', 'v1', credentials=creds)
        profile = service.users().getProfile(userId='me').execute()
        print(f'  Gmail verified: {profile["emailAddress"]}')
    except Exception as e:
        print(f'  Gmail verification failed: {e}')

    print()
    print('Done. The cron job will keep the token fresh from here.')


if __name__ == '__main__':
    main()
