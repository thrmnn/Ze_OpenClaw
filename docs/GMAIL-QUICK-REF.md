# Gmail & Google Workspace Quick Reference

**Last Updated:** 2026-01-30  
**Status:** ✅ Working

---

## Quick Commands

### Test Access
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/test-gmail-access.py
```

### Send Email (Simple)
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email.py \
  --to recipient@example.com \
  --subject "Subject Line" \
  --body "Email body text"
```

### Send Email (From File)
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email.py \
  --to recipient@example.com \
  --subject "Subject Line" \
  --file path/to/content.txt
```

---

## Configuration

**Email Account:** zeclawd@gmail.com  
**Credentials:** `~/clawd/credentials/google-tokens.json`  
**OAuth Client:** `~/clawd/credentials/google-oauth-client.json`  
**Python Env:** `~/clawd/venv-google` (activate before using)

**APIs Available:**
- Gmail (read, send, labels, threads)
- Drive (files, folders, sharing)
- Calendar (events, calendars)

---

## Common Patterns

### Send Email with Full CV Content
```bash
cd ~/clawd && source venv-google/bin/activate
python3 << 'EOF'
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from email.mime.text import MIMEText
import base64

# Read content
with open('path/to/cv.md', 'r') as f:
    cv_content = f.read()

# Load credentials
token_file = Path.home() / "clawd/credentials/google-tokens.json"
creds = Credentials.from_authorized_user_file(str(token_file))
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    with open(token_file, 'w') as f:
        f.write(creds.to_json())

# Send
service = build('gmail', 'v1', credentials=creds)
body = f"Email body:\n\n{cv_content}"
msg = MIMEText(body, 'plain', 'utf-8')
msg['To'] = 'recipient@example.com'
msg['Subject'] = 'Subject'
raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
result = service.users().messages().send(userId='me', body={'raw': raw}).execute()
print(f"Sent! Message ID: {result['id']}")
EOF
```

### List Recent Emails
```bash
cd ~/clawd && source venv-google/bin/activate
python3 << 'EOF'
from pathlib import Path
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

token_file = Path.home() / "clawd/credentials/google-tokens.json"
creds = Credentials.from_authorized_user_file(str(token_file))
service = build('gmail', 'v1', credentials=creds)

# Get recent messages
results = service.users().messages().list(userId='me', maxResults=10).execute()
messages = results.get('messages', [])

for msg in messages:
    m = service.users().messages().get(userId='me', id=msg['id']).execute()
    headers = m['payload']['headers']
    subject = next((h['value'] for h in headers if h['name'] == 'Subject'), 'No Subject')
    from_addr = next((h['value'] for h in headers if h['name'] == 'From'), 'Unknown')
    print(f"From: {from_addr}")
    print(f"Subject: {subject}\n")
EOF
```

---

## Troubleshooting

### Issue: "No module named 'googleapiclient'"
**Solution:** Activate venv-google first
```bash
cd ~/clawd && source venv-google/bin/activate
```

### Issue: "Token expired"
**Solution:** Token auto-refreshes, but you can manually trigger:
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/test-gmail-access.py
```

### Issue: "Permission denied"
**Solution:** Check OAuth scopes in `google-tokens.json`:
```bash
cat ~/clawd/credentials/google-tokens.json | grep -A 10 scopes
```

Should include:
- `https://www.googleapis.com/auth/gmail.send`
- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/drive.file`
- `https://www.googleapis.com/auth/calendar.events`

---

## Scripts Available

1. **`scripts/send-email.py`** - Send email via Gmail API
2. **`scripts/test-gmail-access.py`** - Verify Gmail/Drive/Calendar access

---

## What NOT to Do

❌ **Don't use SMTP** (no credentials configured)  
❌ **Don't use `message` tool for Gmail** (that's for Telegram/WhatsApp)  
❌ **Don't forget to activate venv-google**  
❌ **Don't assume email failed without checking**

---

## Integration with Job Pipeline

When sending CVs or applications via email:

```bash
cd ~/clawd/job-pipeline
CV_FILE="data/applications/company-position/CV-TAILORED.md"
EMAIL="recipient@example.com"

cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email.py \
  --to "$EMAIL" \
  --subject "Application: Position @ Company" \
  --file "$CV_FILE"
```

---

## Verification Checklist

Before using Gmail API in production:
- [ ] Activate venv-google
- [ ] Run test-gmail-access.py
- [ ] Verify email address (zeclawd@gmail.com)
- [ ] Check token is not expired (auto-refreshes)
- [ ] Test send to a safe address first

---

**Last Verified:** 2026-01-30  
**Status:** ✅ All APIs functional  
**Email Sent:** Successfully delivered to alezzandro1.618@gmail.com
