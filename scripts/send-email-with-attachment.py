#!/usr/bin/env python3
"""
Gmail API Email Sender with Attachment Support
Sends emails with optional PDF/file attachments via Google Workspace OAuth

Usage:
    python3 scripts/send-email-with-attachment.py \\
        --to recipient@example.com \\
        --subject "Subject" \\
        --body "Body text" \\
        --attach path/to/file.pdf
"""

import argparse
import base64
import sys
import mimetypes
from pathlib import Path
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication

sys.path.insert(0, str(Path(__file__).parent.parent))

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


def get_gmail_service():
    """Get authenticated Gmail service"""
    token_file = Path.home() / "clawd/credentials/google-tokens.json"
    
    if not token_file.exists():
        raise FileNotFoundError(f"OAuth tokens not found at {token_file}")
    
    creds = Credentials.from_authorized_user_file(str(token_file))
    
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        with open(token_file, 'w') as f:
            f.write(creds.to_json())
    
    return build('gmail', 'v1', credentials=creds)


def send_email_with_attachment(to, subject, body, attachment_path=None, from_email='zeclawd@gmail.com'):
    """Send email with optional attachment via Gmail API"""
    
    # Create multipart message
    msg = MIMEMultipart()
    msg['To'] = to
    msg['From'] = from_email
    msg['Subject'] = subject
    
    # Attach body
    msg.attach(MIMEText(body, 'plain', 'utf-8'))
    
    # Attach file if provided
    if attachment_path:
        file_path = Path(attachment_path)
        if not file_path.exists():
            raise FileNotFoundError(f"Attachment not found: {attachment_path}")
        
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        # Guess MIME type
        mime_type, _ = mimetypes.guess_type(str(file_path))
        if mime_type and mime_type.startswith('application/'):
            subtype = mime_type.split('/')[-1]
        else:
            subtype = 'octet-stream'
        
        attachment = MIMEApplication(file_content, _subtype=subtype)
        attachment.add_header('Content-Disposition', 'attachment', filename=file_path.name)
        msg.attach(attachment)
    
    # Encode and send
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
    message = {'raw': raw}
    
    service = get_gmail_service()
    sent = service.users().messages().send(userId='me', body=message).execute()
    
    return sent


def main():
    parser = argparse.ArgumentParser(description='Send email with attachment via Gmail API')
    parser.add_argument('--to', required=True, help='Recipient email address')
    parser.add_argument('--subject', required=True, help='Email subject')
    parser.add_argument('--body', help='Email body text')
    parser.add_argument('--body-file', dest='body_file', help='File containing email body')
    parser.add_argument('--attach', dest='attachment', help='Path to file to attach')
    parser.add_argument('--from', dest='from_email', default='zeclawd@gmail.com', 
                       help='From email (default: zeclawd@gmail.com)')
    
    args = parser.parse_args()
    
    # Get body content
    if args.body_file:
        with open(args.body_file, 'r') as f:
            body = f.read()
    elif args.body:
        body = args.body
    else:
        print("Error: Either --body or --body-file must be provided")
        sys.exit(1)
    
    # Send email
    try:
        result = send_email_with_attachment(
            args.to, 
            args.subject, 
            body, 
            args.attachment,
            args.from_email
        )
        
        print(f"✅ Email sent successfully!")
        print(f"   Message ID: {result['id']}")
        print(f"   From: {args.from_email}")
        print(f"   To: {args.to}")
        print(f"   Subject: {args.subject}")
        if args.attachment:
            file_size = Path(args.attachment).stat().st_size
            print(f"   Attachment: {Path(args.attachment).name} ({file_size/1024:.1f}KB)")
        return 0
        
    except Exception as e:
        print(f"❌ Email send failed: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
