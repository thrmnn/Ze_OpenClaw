#!/usr/bin/env python3
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

creds = Credentials.from_authorized_user_file(TOKEN_FILE)
drive_service = build('drive', 'v3', credentials=creds)

# Create a Google Doc using Drive API
file_metadata = {
    'name': 'Test from Zé - Hello World',
    'mimeType': 'application/vnd.google-apps.document'
}

file = drive_service.files().create(body=file_metadata, fields='id,name,webViewLink').execute()

# Share with user
drive_service.permissions().create(
    fileId=file['id'],
    body={'type': 'user', 'role': 'writer', 'emailAddress': 'thermann.ai@gmail.com'},
    sendNotificationEmail=True
).execute()

print(f"✅ Document created!")
print(f"   Title: {file['name']}")
print(f"   ID: {file['id']}")
print(f"   URL: {file['webViewLink']}")
print(f"   Shared with: thermann.ai@gmail.com")
print(f"\nNote: Document created empty - you'll need to add 'Hello World' manually or enable Docs API for text insertion")
