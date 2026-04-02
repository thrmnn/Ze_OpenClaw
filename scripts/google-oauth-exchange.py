#!/usr/bin/env python3
"""
Exchange OAuth authorization code for tokens
Usage: python3 google-oauth-exchange.py <authorization-code>
"""

import sys
from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/calendar.readonly'
]

def exchange_code(auth_code):
    client_file = Path.home() / "clawd/credentials/google-oauth-client.json"
    token_file = Path.home() / "clawd/credentials/google-tokens.json"
    
    flow = InstalledAppFlow.from_client_secrets_file(
        str(client_file),
        SCOPES,
        redirect_uri='urn:ietf:wg:oauth:2.0:oob'
    )
    
    # Exchange code for credentials
    flow.fetch_token(code=auth_code)
    creds = flow.credentials
    
    # Save tokens
    with open(token_file, 'w') as f:
        f.write(creds.to_json())
    
    print(f"✅ Tokens saved to: {token_file}")
    print("🎉 OAuth setup complete!")
    
    # Test access
    from googleapiclient.discovery import build
    service = build('gmail', 'v1', credentials=creds)
    profile = service.users().getProfile(userId='me').execute()
    print(f"✅ Gmail access verified: {profile['emailAddress']}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("❌ Usage: python3 google-oauth-exchange.py <authorization-code>")
        sys.exit(1)
    
    auth_code = sys.argv[1]
    exchange_code(auth_code)
