# Tool Reference (Detailed)

Moved from AGENTS.md to save context tokens. Search via `memory_search` when needed.

---

## 📧 Gmail & Google Workspace

**Credentials:** `~/clawd/credentials/google-tokens.json`  
**Email:** zeclawd@gmail.com  
**Venv:** `source ~/clawd/venv-google/bin/activate` (ALWAYS activate first)

### Send Email
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email.py --to recipient@example.com --subject "Subject" --body "Body"
```

### Send with Attachment
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/send-email-with-attachment.py --to recipient@example.com --subject "Subject" --body "Body" --attach path/to/file.pdf
```

### Direct Python (complex emails)
```bash
cd ~/clawd && source venv-google/bin/activate
python3 << 'EOF'
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from email.mime.text import MIMEText
import base64

token_file = Path.home() / "clawd/credentials/google-tokens.json"
creds = Credentials.from_authorized_user_file(str(token_file))
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    with open(token_file, 'w') as f:
        f.write(creds.to_json())

service = build('gmail', 'v1', credentials=creds)
msg = MIMEText("Email body")
msg['To'] = 'recipient@example.com'
msg['Subject'] = 'Subject'
raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
service.users().messages().send(userId='me', body={'raw': raw}).execute()
EOF
```

### Rules
- ❌ Never use SMTP/smtplib
- ❌ Never use message tool for Gmail
- ✅ Token auto-refreshes when expired
- ✅ Gmail, Drive, Calendar all share same credentials

### Test
```bash
cd ~/clawd && source venv-google/bin/activate
python3 scripts/test-gmail-access.py
```

### LaTeX PDF (for CVs)
```bash
pdflatex -interaction=nonstopmode cv.tex
```
- Use `article` class (simpler, no deps)
- Avoid `moderncv` (needs fontawesome, not installed)

---

## 🎤 Voice Message Handling

**Transcribe immediately** using local Whisper:
```bash
python3 scripts/audio-transcribe-local.py <audio_file> --model tiny
```

**Workflow:** Receive → Transcribe → Process text → Delete audio  
**Privacy:** All local, no external APIs

---

## 📝 Platform Formatting

- **Discord/WhatsApp:** No markdown tables — use bullet lists
- **Discord links:** Wrap in `<>` to suppress embeds
- **WhatsApp:** No headers — use **bold** or CAPS

---

## 🎭 Voice Storytelling

Use `sag` (ElevenLabs TTS) for stories, movie summaries, narration. Surprise with funny voices.
