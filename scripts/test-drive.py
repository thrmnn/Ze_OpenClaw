#!/usr/bin/env python3
"""
Quick Drive test - list recent files shared with me
"""

import os
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def list_shared_files():
    """List files shared with me"""
    creds = Credentials.from_authorized_user_file(TOKEN_FILE)
    service = build('drive', 'v3', credentials=creds)
    
    print("📁 Files shared with me:\n")
    
    # List files shared with me
    results = service.files().list(
        q="sharedWithMe=true",
        pageSize=10,
        fields="files(id, name, mimeType, modifiedTime, owners, webViewLink)"
    ).execute()
    
    files = results.get('files', [])
    
    if not files:
        print("No files found.")
        return
    
    for i, f in enumerate(files, 1):
        owner = f.get('owners', [{}])[0].get('displayName', 'Unknown')
        print(f"{i}. {f['name']}")
        print(f"   Type: {f['mimeType'].split('.')[-1]}")
        print(f"   Owner: {owner}")
        print(f"   Modified: {f['modifiedTime']}")
        print(f"   Link: {f.get('webViewLink', 'N/A')}")
        print()

if __name__ == '__main__':
    try:
        list_shared_files()
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
