#!/usr/bin/env python3
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

creds = Credentials.from_authorized_user_file(TOKEN_FILE)

# Create doc
docs_service = build('docs', 'v1', credentials=creds)
doc = docs_service.documents().create(body={'title': 'Test from Zé - Hello World'}).execute()
doc_id = doc['documentId']

# Insert text
requests = [{
    'insertText': {
        'location': {'index': 1},
        'text': 'Hello World! 🌍\n\nThis document was created by Zé (Clawdbot) to test Google Workspace integration.\n\nDate: 2026-01-27\n'
    }
}]
docs_service.documents().batchUpdate(documentId=doc_id, body={'requests': requests}).execute()

# Share with user
drive_service = build('drive', 'v3', credentials=creds)
drive_service.permissions().create(
    fileId=doc_id,
    body={'type': 'user', 'role': 'writer', 'emailAddress': 'thermann.ai@gmail.com'}
).execute()

print(f"✅ Document created!")
print(f"   Title: Test from Zé - Hello World")
print(f"   ID: {doc_id}")
print(f"   URL: https://docs.google.com/document/d/{doc_id}/edit")
print(f"   Shared with: thermann.ai@gmail.com")
