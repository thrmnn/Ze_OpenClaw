#!/usr/bin/env python3
"""
fetch_email.py - Fetch Gmail unread count and flagged/important emails for morning brief.
Returns JSON: {"unread": N, "flagged": [{"sender": "...", "subject": "..."}]}
"""

import json
import sys
import argparse
from pathlib import Path


def fetch_email():
    try:
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
        from googleapiclient.discovery import build

        token_file = Path.home() / "clawd/credentials/google-tokens.json"
        if not token_file.exists():
            return {"unread": 0, "flagged": [], "error": "credentials not found"}

        creds = Credentials.from_authorized_user_file(str(token_file))

        if creds.expired and creds.refresh_token:
            creds.refresh(Request())
            with open(token_file, 'w') as f:
                f.write(creds.to_json())

        service = build('gmail', 'v1', credentials=creds)

        # Count unread in inbox
        inbox_result = service.users().labels().get(userId='me', id='INBOX').execute()
        unread_count = inbox_result.get('messagesUnread', 0)

        # Find flagged: starred OR IMPORTANT label
        flagged = []

        # Starred emails (max 3)
        starred_result = service.users().messages().list(
            userId='me',
            q='is:starred is:unread',
            maxResults=3
        ).execute()
        starred_msgs = starred_result.get('messages', [])

        for msg in starred_msgs[:3]:
            msg_detail = service.users().messages().get(
                userId='me',
                id=msg['id'],
                format='metadata',
                metadataHeaders=['From', 'Subject']
            ).execute()
            headers = {h['name']: h['value'] for h in msg_detail.get('payload', {}).get('headers', [])}
            sender = headers.get('From', 'Unknown')
            subject = headers.get('Subject', '(no subject)')
            flagged.append({"sender": sender, "subject": subject})

        # If we still have room, add IMPORTANT unread (not already captured)
        if len(flagged) < 3:
            important_result = service.users().messages().list(
                userId='me',
                q='label:important is:unread -is:starred',
                maxResults=3 - len(flagged)
            ).execute()
            important_msgs = important_result.get('messages', [])

            for msg in important_msgs:
                if len(flagged) >= 3:
                    break
                msg_detail = service.users().messages().get(
                    userId='me',
                    id=msg['id'],
                    format='metadata',
                    metadataHeaders=['From', 'Subject']
                ).execute()
                headers = {h['name']: h['value'] for h in msg_detail.get('payload', {}).get('headers', [])}
                sender = headers.get('From', 'Unknown')
                subject = headers.get('Subject', '(no subject)')
                flagged.append({"sender": sender, "subject": subject})

        return {"unread": unread_count, "flagged": flagged[:3]}

    except Exception as e:
        return {"unread": 0, "flagged": [], "error": str(e)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fetch Gmail unread and flagged emails")
    parser.add_argument("--test", action="store_true", help="Print JSON output and exit")
    args = parser.parse_args()

    result = fetch_email()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(0)
