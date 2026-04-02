#!/usr/bin/env python3
"""
Gmail + Drive OAuth with WRITE scope
"""

import os
from google_auth_oauthlib.flow import Flow

SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.file'  # NEW: Write scope
]

CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def generate_auth_url():
    """Generate OAuth URL"""
    flow = Flow.from_client_secrets_file(
        CREDS_FILE,
        scopes=SCOPES,
        redirect_uri='urn:ietf:wg:oauth:2.0:oob'
    )
    
    auth_url, _ = flow.authorization_url(prompt='consent')
    
    print("🔐 OAuth Authorization URL:")
    print("=" * 80)
    print(auth_url)
    print("=" * 80)
    print("\n📋 Steps:")
    print("1. Open the URL above in your browser")
    print("2. Login with zeclawd@gmail.com")
    print("3. Authorize the new permissions (drive.file)")
    print("4. Copy the authorization code")
    print("5. Send the code to me")
    
    return auth_url

if __name__ == '__main__':
    generate_auth_url()
