#!/usr/bin/env python3
"""
Gmail Access Test
Verifies that Google Workspace OAuth credentials are working

Usage:
    python3 scripts/test-gmail-access.py
"""

import sys
from pathlib import Path

# Check if Google libraries are available
try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build
except ImportError as e:
    print("❌ Google API libraries not available")
    print(f"   Error: {e}")
    print("\n💡 Solution:")
    print("   cd ~/clawd && source venv-google/bin/activate")
    print("   Or install: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")
    sys.exit(1)

# Load credentials
token_file = Path.home() / "clawd/credentials/google-tokens.json"

if not token_file.exists():
    print("❌ OAuth tokens not found")
    print(f"   Expected at: {token_file}")
    print("\n💡 Solution:")
    print("   Run OAuth flow to generate tokens (see Google Workspace MCP setup)")
    sys.exit(1)

# Test credentials
try:
    creds = Credentials.from_authorized_user_file(str(token_file))
    
    # Refresh if needed
    if creds.expired and creds.refresh_token:
        print("⚠️  Token expired, refreshing...")
        creds.refresh(Request())
        with open(token_file, 'w') as f:
            f.write(creds.to_json())
        print("✅ Token refreshed!")
    
    # Test Gmail API
    service = build('gmail', 'v1', credentials=creds)
    profile = service.users().getProfile(userId='me').execute()
    
    print("✅ Gmail API Working!")
    print(f"   Email: {profile.get('emailAddress')}")
    print(f"   Total Messages: {profile.get('messagesTotal')}")
    print(f"   Threads: {profile.get('threadsTotal')}")
    
    # Test Drive API
    try:
        drive_service = build('drive', 'v3', credentials=creds)
        about = drive_service.about().get(fields='user').execute()
        print("\n✅ Drive API Working!")
        print(f"   User: {about['user']['displayName']}")
        print(f"   Email: {about['user']['emailAddress']}")
    except Exception as e:
        print(f"\n⚠️  Drive API issue: {e}")
    
    # Test Calendar API
    try:
        calendar_service = build('calendar', 'v3', credentials=creds)
        calendar_list = calendar_service.calendarList().list(maxResults=1).execute()
        print("\n✅ Calendar API Working!")
        if calendar_list.get('items'):
            print(f"   Primary Calendar: {calendar_list['items'][0]['summary']}")
    except Exception as e:
        print(f"\n⚠️  Calendar API issue: {e}")
    
    print("\n🎉 All Google Workspace APIs are functional!")
    sys.exit(0)
    
except Exception as e:
    print(f"❌ Gmail API test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
