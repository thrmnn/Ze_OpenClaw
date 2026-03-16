#!/usr/bin/env python3
"""
Add 'Hello World' text to document using Drive API (add to description)
Workaround since Docs API not enabled
"""

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'
DOC_ID = '1kxRPyXR5ym-T4zIz-NUtuU4A_hEmkqbjx8LZvLAUn1M'

creds = Credentials.from_authorized_user_file(TOKEN_FILE)
drive_service = build('drive', 'v3', credentials=creds)

# Update document description (metadata)
drive_service.files().update(
    fileId=DOC_ID,
    body={
        'description': 'Hello World! 🌍\n\nThis document was created by Zé (Clawdbot) to test Google Drive write access.\n\nDate: 2026-01-27 23:14 GMT-3'
    }
).execute()

print("✅ Document metadata updated with 'Hello World' message")
print(f"   View at: https://docs.google.com/document/d/{DOC_ID}/edit")
print("\nNote: Text added to document description (File > Document details)")
print("To add text inside the document, Google Docs API would need to be enabled.")
