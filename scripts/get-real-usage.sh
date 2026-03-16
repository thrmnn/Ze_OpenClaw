#!/bin/bash
# Get real Claude Code usage (not just Clawdbot session tokens)

cd /home/theo/clawd
source venv-google/bin/activate 2>/dev/null

# Use claude-monitor to get real usage
# Parse the output to extract percentage
timeout 3 claude-monitor --plan pro --timezone America/Sao_Paulo 2>&1 | \
  grep -E "Usage:|Tokens:" | head -1 || echo "Usage data unavailable"
