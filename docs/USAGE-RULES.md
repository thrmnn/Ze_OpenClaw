# Claude Usage Monitoring Rules

## ⚠️ IMPORTANT: Usage Display Updated

**What I show:**
- **Session tokens:** This Clawdbot session only (for context management)
- **NOT:** Your real Claude Pro usage limits

**To check real Pro usage:**
```bash
npx ccusage                     # Daily history
claude-monitor --plan pro       # Real-time monitor
```

**Or check:** https://console.anthropic.com/settings/usage

---

## Context Management (Session Tokens)

### Thresholds for THIS Session:
- 🟢 0-70%: Normal
- 🟡 70-85%: Compress soon
- 🟠 85-95%: Compress now
- 🔴 95-100%: New session

### Response Format
**Every response shows:**
- Session tokens (X% of 200k)
- NOT Pro usage limits

---

## Real Usage Monitoring

**Commands:**
```bash
# Daily usage history
npx ccusage

# Real-time monitor (interactive)
cd /home/theo/clawd && source venv-google/bin/activate
claude-monitor --plan pro --timezone America/Sao_Paulo

# Quick check
./scripts/check-usage.sh
```

---

## Note

Session token % helps me manage context compression.
For your actual Pro usage/limits, use the commands above or check Anthropic console.
