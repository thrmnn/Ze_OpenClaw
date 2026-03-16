#!/bin/bash
# Brisa+ Paper Workflow Automation
# Based on LAI paper system with Brisa+ specifics

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault"
PROJECT_PATH="$VAULT_PATH/Projects/Academic Research/Brisa+ Paper"
FEEDBACK_LOG="$PROJECT_PATH/Feedback Log.md"

# Paper location (CONFIGURED)
PAPER_DIR="/home/theo/brisa_paper/artifacts/latex"
PAPER_TEX="$PAPER_DIR/main.tex"
PAPER_PDF="$PAPER_DIR/main.pdf"

# SAFETY: This is professional academic work
# - Git repository at /home/theo/brisa_paper
# - NEVER modify manuscript content without explicit approval
# - ALWAYS commit before ANY changes
# - ALWAYS sync with GitHub after commits
# - READ: /home/theo/brisa_paper/CLAUDE.md before ANY edit

ACTION="$1"
shift

case "$ACTION" in
  
  feedback)
    FEEDBACK_TEXT="$*"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
    
    echo "📝 Logging feedback to Obsidian..."
    
    cat >> "$FEEDBACK_LOG" << EOF

### **Revision $(date +%Y%m%d-%H%M) - $TIMESTAMP**
**Feedback:**
$FEEDBACK_TEXT

**Changes Proposed:**
*Zé will analyze and propose changes*

**Status:**
- [x] Received
- [ ] Proposed
- [ ] Approved
- [ ] Implemented
- [ ] Compiled
- [ ] Emailed

---
EOF
    
    echo "✅ Feedback logged"
    ;;
  
  compile)
    echo "🔨 Compiling Brisa+ paper..."
    
    if [ ! -f "$PAPER_TEX" ]; then
      echo "❌ LaTeX file not found: $PAPER_TEX"
      exit 1
    fi
    
    cd "$(dirname "$PAPER_TEX")" || exit 1
    
    # Compile with pdflatex (adjust if different)
    pdflatex -interaction=nonstopmode "$(basename "$PAPER_TEX")" 2>&1 | tail -20
    
    if [ $? -eq 0 ] && [ -f "$PAPER_PDF" ]; then
      echo "✅ PDF compiled successfully: $PAPER_PDF"
    else
      echo "❌ Compilation failed"
      exit 1
    fi
    ;;
  
  email)
    RECIPIENT="$1"
    SUBJECT="${2:-Brisa+ Paper - Updated Version}"
    
    if [ -z "$RECIPIENT" ]; then
      echo "Usage: $0 email recipient@example.com [subject]"
      exit 1
    fi
    
    if [ ! -f "$PAPER_PDF" ]; then
      echo "❌ PDF not found. Run 'compile' first"
      exit 1
    fi
    
    echo "📧 Sending PDF to $RECIPIENT..."
    
    cd ~/clawd && source venv-google/bin/activate
    python3 scripts/send-email-with-attachment.py \
      --to "$RECIPIENT" \
      --subject "$SUBJECT" \
      --body "Please find attached the updated Brisa+ paper.

Version: $(date '+%Y-%m-%d %H:%M')
Sent by: Zé (automated workflow)

Best regards,
Théo" \
      --attach "$PAPER_PDF"
    
    if [ $? -eq 0 ]; then
      echo "✅ Email sent successfully"
    else
      echo "❌ Email failed"
      exit 1
    fi
    ;;
  
  publish)
    RECIPIENT="$1"
    
    if [ -z "$RECIPIENT" ]; then
      echo "Usage: $0 publish recipient@example.com"
      exit 1
    fi
    
    $0 compile && $0 email "$RECIPIENT" "Brisa+ Paper - $(date +%Y-%m-%d)"
    ;;
  
  status)
    echo "📊 Brisa+ Paper Status"
    echo "======================="
    echo ""
    echo "LaTeX Source: $PAPER_TEX"
    [ -f "$PAPER_TEX" ] && echo "  ✅ Found" || echo "  ❌ Not found"
    
    echo "PDF Output: $PAPER_PDF"
    [ -f "$PAPER_PDF" ] && echo "  ✅ Found" || echo "  ❌ Not found"
    
    echo "Feedback Log: $FEEDBACK_LOG"
    [ -f "$FEEDBACK_LOG" ] && echo "  ✅ Found" || echo "  ❌ Not found"
    
    echo ""
    echo "Git Status:"
    cd /home/theo/brisa_paper && git status --short
    ;;
  
  *)
    cat << EOF
Brisa+ Paper Workflow Automation

Usage: $0 <command> [args]

Commands:
  feedback <text>        Log feedback
  compile                Compile LaTeX → PDF
  email <to> [subject]   Email PDF
  publish <to>           Compile + Email
  status                 Show current status

Examples:
  $0 feedback "Revise literature review section 2.3"
  $0 compile
  $0 email supervisor@uni.edu
  $0 publish supervisor@uni.edu

Configuration:
  Repository: /home/theo/brisa_paper
  Main file: artifacts/latex/main.tex
  
Safety:
  - Read /home/theo/brisa_paper/CLAUDE.md before editing
  - Use brisa-paper-safety-protocols.sh for all changes

EOF
    ;;
esac
