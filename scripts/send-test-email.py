#!/usr/bin/env python3
import sys
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import base64
from email.mime.text import MIMEText

TOKEN_FILE = '/home/theo/clawd/credentials/google-tokens.json'

creds = Credentials.from_authorized_user_file(TOKEN_FILE)
service = build('gmail', 'v1', credentials=creds)

to_email = sys.argv[1] if len(sys.argv) > 1 else "thermann.ai@gmail.com"

message = MIMEText("Hello from Zé! 👋\n\nThis is a test email from your Clawdbot assistant.\n\nGoogle Workspace integration is working!\n\n- Zé")
message['to'] = to_email
message['subject'] = "✅ Test from Zé (Clawdbot)"

raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
result = service.users().messages().send(userId='me', body={'raw': raw}).execute()
print(f"✅ Email sent! Message ID: {result['id']}")
