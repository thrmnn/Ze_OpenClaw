# Google Drive & Gmail API Setup Plan

## Goal
Enable Zé to access Google Drive files and Gmail for:
- Reading/searching emails
- Sending emails
- Accessing documents in Drive
- Managing calendar events
- Organizing files

---

## Architecture Options

### Option 1: **MCP Server** (⭐ RECOMMENDED)
Use Model Context Protocol server for Google Workspace

**Advantages:**
- Native integration with Claude Code
- Follows same pattern as Trello
- Easy to manage
- Standardized interface

**Available MCP Servers:**
- Check npm for `@modelcontextprotocol/server-gdrive` or similar
- Community MCP servers for Google APIs

### Option 2: **Custom Skill**
Create a Clawdbot skill with direct API access

**Advantages:**
- Full control
- Custom workflows
- Can optimize for your use case

**Disadvantages:**
- More maintenance
- Need to handle auth ourselves

### Option 3: **Python Script + OAuth**
Simple Python scripts with Google API client

**Advantages:**
- Quick to prototype
- Direct API access
- Easy to debug

**Disadvantages:**
- Not integrated with Clawdbot
- Manual execution

---

## Google Cloud Setup Steps

### 1. **Create Google Cloud Project**

```bash
# Go to: https://console.cloud.google.com/
# 1. Create new project: "Clawdbot Integration"
# 2. Note the Project ID
```

### 2. **Enable APIs**

Required APIs:
- Gmail API
- Google Drive API
- Google Calendar API (optional)
- Google Sheets API (optional)

```bash
# Via Console:
# https://console.cloud.google.com/apis/library
# Search and enable each API
```

### 3. **Create OAuth 2.0 Credentials**

**For Desktop Application:**

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: "Desktop app"
4. Name: "Clawdbot Desktop Client"
5. Download credentials JSON

**Save as:** `/home/theo/clawd/credentials/google-oauth-client.json`

### 4. **Configure OAuth Consent Screen**

1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. User Type: "External" (unless you have Google Workspace)
3. Fill required fields:
   - App name: "Clawdbot"
   - User support email: your email
   - Developer contact: your email
4. Scopes: Add required scopes (see below)
5. Add yourself as test user

---

## Required OAuth Scopes

```javascript
const SCOPES = [
  // Gmail
  'https://www.googleapis.com/auth/gmail.readonly',     // Read emails
  'https://www.googleapis.com/auth/gmail.send',         // Send emails
  'https://www.googleapis.com/auth/gmail.modify',       // Modify emails (labels, etc.)
  
  // Drive
  'https://www.googleapis.com/auth/drive.readonly',     // Read Drive files
  'https://www.googleapis.com/auth/drive.file',         // Create/modify files created by app
  'https://www.googleapis.com/auth/drive.metadata.readonly', // Read file metadata
  
  // Calendar (optional)
  'https://www.googleapis.com/auth/calendar.readonly',  // Read calendar
  'https://www.googleapis.com/auth/calendar.events',    // Create/modify events
];
```

---

## Implementation Approach

### **Phase 1: Search for Existing MCP Server**

```bash
# Check npm for Google MCP servers
npm search mcp-server-google
npm search mcp-server-gdrive
npm search mcp-server-gmail
```

### **Phase 2: Install or Create MCP Server**

**If MCP server exists:**
```bash
# Install it
claude mcp add gdrive -- npx -y <package-name>

# Configure with OAuth
# (Each server has its own config method)
```

**If no MCP server exists:**
Create custom implementation (see below)

### **Phase 3: OAuth Flow**

**First-time authentication:**
```bash
# Run OAuth flow
node scripts/google-auth.js

# Opens browser → Login → Grant permissions → Get tokens
# Saves tokens to: credentials/google-tokens.json
```

**Token structure:**
```json
{
  "access_token": "ya29.xxx",
  "refresh_token": "1//xxx",
  "scope": "https://www.googleapis.com/auth/gmail.readonly ...",
  "token_type": "Bearer",
  "expiry_date": 1706389200000
}
```

---

## Custom Implementation (If No MCP Server)

### 1. **Install Google API Client**

```bash
cd /home/theo/clawd
source venv-whisper/bin/activate  # Or create new venv
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-tools
```

### 2. **Authentication Script**

**Location:** `/home/theo/clawd/scripts/google-auth.py`

```python
#!/usr/bin/env python3
"""
Google OAuth authentication flow
Generates and saves tokens for Gmail/Drive API access
"""

import os
import json
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials

# Scopes
SCOPES = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.send',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
]

CREDENTIALS_FILE = '/home/theo/clawd/credentials/google-oauth-client.json'
TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def authenticate():
    """Run OAuth flow and save tokens"""
    creds = None
    
    # Load existing tokens if available
    if os.path.exists(TOKEN_FILE):
        creds = Credentials.from_authorized_user_file(TOKEN_FILE, SCOPES)
    
    # If no valid credentials, run OAuth flow
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CREDENTIALS_FILE, SCOPES
            )
            creds = flow.run_local_server(port=0)
        
        # Save credentials
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
        
        print(f"✅ Tokens saved to {TOKEN_FILE}")
    else:
        print("✅ Valid tokens found")
    
    return creds

if __name__ == '__main__':
    authenticate()
    print("Authentication complete!")
```

### 3. **Gmail Helper Script**

**Location:** `/home/theo/clawd/scripts/gmail.py`

```python
#!/usr/bin/env python3
"""
Gmail helper - search, read, send emails
Usage:
  ./gmail.py search "subject:invoice"
  ./gmail.py read <message-id>
  ./gmail.py send --to "email@example.com" --subject "Test" --body "Hello"
"""

import sys
import base64
from email.mime.text import MIMEText
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def get_service():
    """Get authenticated Gmail service"""
    creds = Credentials.from_authorized_user_file(TOKEN_FILE)
    return build('gmail', 'v1', credentials=creds)

def search_emails(query):
    """Search emails with Gmail query"""
    service = get_service()
    results = service.users().messages().list(userId='me', q=query, maxResults=10).execute()
    messages = results.get('messages', [])
    
    for msg in messages:
        full_msg = service.users().messages().get(userId='me', id=msg['id'], format='metadata').execute()
        headers = {h['name']: h['value'] for h in full_msg['payload']['headers']}
        print(f"ID: {msg['id']}")
        print(f"From: {headers.get('From', 'Unknown')}")
        print(f"Subject: {headers.get('Subject', 'No subject')}")
        print(f"Date: {headers.get('Date', 'Unknown')}")
        print("---")

def read_email(message_id):
    """Read full email content"""
    service = get_service()
    msg = service.users().messages().get(userId='me', id=message_id, format='full').execute()
    
    # Extract headers
    headers = {h['name']: h['value'] for h in msg['payload']['headers']}
    print(f"From: {headers.get('From')}")
    print(f"Subject: {headers.get('Subject')}")
    print(f"Date: {headers.get('Date')}")
    print("\n--- Body ---")
    
    # Extract body
    if 'parts' in msg['payload']:
        parts = msg['payload']['parts']
        data = parts[0]['body']['data']
    else:
        data = msg['payload']['body']['data']
    
    body = base64.urlsafe_b64decode(data).decode('utf-8')
    print(body)

def send_email(to, subject, body):
    """Send email"""
    service = get_service()
    
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject
    
    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    send_msg = {'raw': raw}
    
    result = service.users().messages().send(userId='me', body=send_msg).execute()
    print(f"✅ Email sent! Message ID: {result['id']}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: gmail.py [search|read|send] [args...]")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == 'search':
        search_emails(sys.argv[2])
    elif cmd == 'read':
        read_email(sys.argv[2])
    elif cmd == 'send':
        # Parse --to, --subject, --body
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('--to', required=True)
        parser.add_argument('--subject', required=True)
        parser.add_argument('--body', required=True)
        args = parser.parse_args(sys.argv[2:])
        send_email(args.to, args.subject, args.body)
    else:
        print(f"Unknown command: {cmd}")
```

### 4. **Drive Helper Script**

**Location:** `/home/theo/clawd/scripts/gdrive.py`

```python
#!/usr/bin/env python3
"""
Google Drive helper - list, search, download files
Usage:
  ./gdrive.py list
  ./gdrive.py search "name contains 'report'"
  ./gdrive.py download <file-id> <output-path>
"""

import sys
import io
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

def get_service():
    """Get authenticated Drive service"""
    creds = Credentials.from_authorized_user_file(TOKEN_FILE)
    return build('drive', 'v3', credentials=creds)

def list_files():
    """List recent files"""
    service = get_service()
    results = service.files().list(
        pageSize=20,
        fields="files(id, name, mimeType, modifiedTime)"
    ).execute()
    
    files = results.get('files', [])
    for f in files:
        print(f"{f['id']} | {f['name']} | {f['mimeType']} | {f['modifiedTime']}")

def search_files(query):
    """Search files"""
    service = get_service()
    results = service.files().list(
        q=query,
        pageSize=20,
        fields="files(id, name, mimeType, modifiedTime)"
    ).execute()
    
    files = results.get('files', [])
    for f in files:
        print(f"{f['id']} | {f['name']} | {f['mimeType']}")

def download_file(file_id, output_path):
    """Download file"""
    service = get_service()
    request = service.files().get_media(fileId=file_id)
    
    fh = io.FileIO(output_path, 'wb')
    downloader = MediaIoBaseDownload(fh, request)
    
    done = False
    while not done:
        status, done = downloader.next_chunk()
        print(f"Download {int(status.progress() * 100)}%")
    
    print(f"✅ Downloaded to {output_path}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: gdrive.py [list|search|download] [args...]")
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == 'list':
        list_files()
    elif cmd == 'search':
        search_files(sys.argv[2])
    elif cmd == 'download':
        download_file(sys.argv[2], sys.argv[3])
    else:
        print(f"Unknown command: {cmd}")
```

---

## MCP Server Wrapper (If Using Scripts)

**Location:** `/home/theo/clawd/credentials/google-mcp.sh`

```bash
#!/bin/bash
# Wrapper to expose Google APIs via MCP-like interface

CMD=$1
shift

case "$CMD" in
  gmail-search)
    /home/theo/clawd/scripts/gmail.py search "$@"
    ;;
  gmail-read)
    /home/theo/clawd/scripts/gmail.py read "$@"
    ;;
  gmail-send)
    /home/theo/clawd/scripts/gmail.py send "$@"
    ;;
  drive-list)
    /home/theo/clawd/scripts/gdrive.py list
    ;;
  drive-search)
    /home/theo/clawd/scripts/gdrive.py search "$@"
    ;;
  drive-download)
    /home/theo/clawd/scripts/gdrive.py download "$@"
    ;;
  *)
    echo "Unknown command: $CMD"
    exit 1
    ;;
esac
```

---

## Setup Checklist

- [ ] Create Google Cloud project
- [ ] Enable Gmail API
- [ ] Enable Drive API
- [ ] Create OAuth credentials (desktop app)
- [ ] Download client JSON → `credentials/google-oauth-client.json`
- [ ] Configure OAuth consent screen
- [ ] Add test user (yourself)
- [ ] Search for existing MCP server
- [ ] If none: Install google-api-python-client
- [ ] Create authentication script
- [ ] Run OAuth flow → get tokens
- [ ] Test Gmail access (search, read)
- [ ] Test Drive access (list files)
- [ ] Create helper scripts for common operations
- [ ] Document usage in TOOLS.md
- [ ] Add to Clawdbot workflow

---

## Quick Start Commands

```bash
# 1. Authenticate
python3 scripts/google-auth.py

# 2. Test Gmail
python3 scripts/gmail.py search "is:unread"

# 3. Test Drive
python3 scripts/gdrive.py list

# 4. Check for MCP servers
npm search mcp-server-google
npm search @modelcontextprotocol/server-google
```

---

## Security Notes

- `credentials/google-oauth-client.json` - Client ID/secret (gitignored)
- `credentials/google-tokens.json` - Access/refresh tokens (gitignored)
- Tokens expire: refresh tokens last indefinitely
- Keep credentials folder secure
- Never commit to git

---

## Next Steps

1. **Now:** Create Google Cloud project
2. **Now:** Enable APIs
3. **Now:** Create OAuth credentials
4. **Then:** Install dependencies + run auth flow
5. **Then:** Test basic operations
6. **Later:** Build MCP integration or Clawdbot skill
