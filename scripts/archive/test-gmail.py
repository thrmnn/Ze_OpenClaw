#!/usr/bin/env python3
"""
Quick Gmail test - triggers OAuth flow and lists recent emails
"""

import os
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']
CREDS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def authenticate():
    """Authenticate and return credentials"""
    creds = None
    
    # Load existing tokens
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    
    # If no valid credentials, run OAuth flow
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print("♻️  Refreshing expired token...")
            creds.refresh(Request())
        else:
            print("🔐 Starting OAuth flow...")
            print("A browser window will open for authorization.")
            flow = InstalledAppFlow.from_client_secrets_file(CREDS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save credentials
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
        print(f"✅ Tokens saved to {TOKEN_FILE}")
    else:
        print("✅ Valid tokens found")
    
    return creds

def list_recent_emails(count=5):
    """List recent emails"""
    creds = authenticate()
    service = build('gmail', 'v1', credentials=creds)
    
    print(f"\n📧 Fetching {count} most recent emails...\n")
    
    results = service.users().messages().list(
        userId='me',
        maxResults=count
    ).execute()
    
    messages = results.get('messages', [])
    
    if not messages:
        print("No messages found.")
        return
    
    for i, msg in enumerate(messages, 1):
        # Get message details
        message = service.users().messages().get(
            userId='me',
            id=msg['id'],
            format='metadata',
            metadataHeaders=['From', 'Subject', 'Date']
        ).execute()
        
        headers = {h['name']: h['value'] for h in message['payload']['headers']}
        
        print(f"{i}. From: {headers.get('From', 'Unknown')}")
        print(f"   Subject: {headers.get('Subject', 'No subject')}")
        print(f"   Date: {headers.get('Date', 'Unknown')}")
        print()

if __name__ == '__main__':
    try:
        list_recent_emails()
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
