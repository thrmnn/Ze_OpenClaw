#!/usr/bin/env python3
"""
Gmail API Email Sender
Uses Google Workspace OAuth credentials to send emails from zeclawd@gmail.com

Usage:
    python3 scripts/send-email.py --to recipient@example.com --subject "Subject" --body "Body text"
    python3 scripts/send-email.py --to recipient@example.com --subject "Subject" --file path/to/content.txt
"""

import argparse
import base64
import sys
from pathlib import Path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


def get_gmail_service():
    """Get authenticated Gmail service"""
    token_file = Path.home() / "clawd/credentials/google-tokens.json"
    
    if not token_file.exists():
        raise FileNotFoundError(f"OAuth tokens not found at {token_file}")
    
    # Load credentials
    creds = Credentials.from_authorized_user_file(str(token_file))
    
    # Refresh if expired
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        # Save refreshed token
        with open(token_file, 'w') as f:
            f.write(creds.to_json())
    
    # Build and return service
    return build('gmail', 'v1', credentials=creds)


def send_email(to, subject, body, from_email='zeclawd@gmail.com'):
    """Send email via Gmail API"""
    
    # Create message
    msg = MIMEMultipart()
    msg['To'] = to
    msg['From'] = from_email
    msg['Subject'] = subject
    
    msg.attach(MIMEText(body, 'plain', 'utf-8'))
    
    # Encode and send
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
    message = {'raw': raw}
    
    # Get Gmail service and send
    service = get_gmail_service()
    sent = service.users().messages().send(userId='me', body=message).execute()
    
    return sent


def main():
    parser = argparse.ArgumentParser(description='Send email via Gmail API')
    parser.add_argument('--to', required=True, help='Recipient email address')
    parser.add_argument('--subject', required=True, help='Email subject')
    parser.add_argument('--body', help='Email body text')
    parser.add_argument('--file', help='File containing email body')
    parser.add_argument('--from', dest='from_email', default='zeclawd@gmail.com', help='From email (default: zeclawd@gmail.com)')
    
    args = parser.parse_args()
    
    # Get body content
    if args.file:
        with open(args.file, 'r') as f:
            body = f.read()
    elif args.body:
        body = args.body
    else:
        print("Error: Either --body or --file must be provided")
        sys.exit(1)
    
    # Send email
    try:
        result = send_email(args.to, args.subject, body, args.from_email)
        print(f"✅ Email sent successfully!")
        print(f"   Message ID: {result['id']}")
        print(f"   From: {args.from_email}")
        print(f"   To: {args.to}")
        print(f"   Subject: {args.subject}")
        return 0
    except Exception as e:
        print(f"❌ Email send failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
