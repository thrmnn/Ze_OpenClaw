#!/usr/bin/env python3
"""
Gmail OAuth - Manual flow for WSL
Generates URL for user to open in browser
"""

import os
import json
from google_auth_oauthlib.flow import Flow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly'
]

CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def manual_oauth():
    """OAuth flow with manual URL"""
    
    # Check if tokens already exist
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
        if creds.valid:
            print("✅ Valid tokens already exist!")
            print(f"   Token file: {TOKEN_FILE}")
            return creds
        elif creds.expired and creds.refresh_token:
            print("♻️  Refreshing expired token...")
            creds.refresh(Request())
            with open(TOKEN_FILE, 'w') as token:
                token.write(creds.to_json())
            print("✅ Token refreshed!")
            return creds
    
    # Start manual OAuth flow
    print("🔐 Starting OAuth authorization...\n")
    
    flow = Flow.from_client_secrets_file(
        CREDS_FILE,
        scopes=SCOPES,
        redirect_uri='urn:ietf:wg:oauth:2.0:oob'  # Manual flow
    )
    
    auth_url, _ = flow.authorization_url(prompt='consent')
    
    print("📋 STEP 1: Open this URL in your browser:")
    print("-" * 80)
    print(auth_url)
    print("-" * 80)
    print()
    
    # Get authorization code from user
    code = input("📥 STEP 2: Paste the authorization code here: ").strip()
    
    # Exchange code for tokens
    print("\n⏳ Exchanging code for tokens...")
    flow.fetch_token(code=code)
    creds = flow.credentials
    
    # Save tokens
    with open(TOKEN_FILE, 'w') as token:
        token.write(creds.to_json())
    
    print(f"✅ Success! Tokens saved to: {TOKEN_FILE}")
    print("\nYou can now use Gmail and Drive APIs!")
    
    return creds

if __name__ == '__main__':
    try:
        manual_oauth()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelled by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
