#!/bin/bash
# LAI Paper Workflow Automation
# Handles: feedback → propose changes → implement → compile → email

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Research_Vault"
PROJECT_PATH="$VAULT_PATH/Projects/Academic Research/LAI Paper"
FEEDBACK_LOG="$PROJECT_PATH/Feedback Log.md"

# Paper location (CONFIGURED)
PAPER_DIR="/home/theo/lai_paper/draft"
PAPER_TEX="$PAPER_DIR/sn-article.tex"  # Main manuscript file
PAPER_PDF="$PAPER_DIR/sn-article.pdf"

# SAFETY: This is professional academic work
# - Git repository at /home/theo/lai_paper
# - NEVER modify manuscript content without explicit approval
# - ALWAYS commit before ANY changes
# - ALWAYS sync with GitHub after commits

ACTION="$1"
shift  # Remove first arg, rest are parameters

case "$ACTION" in
  
  # Log new feedback
  feedback)
    FEEDBACK_TEXT="$*"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
    
    echo "📝 Logging feedback to Obsidian..."
    
    # Append to Feedback Log
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
    
    echo "✅ Feedback logged to: Projects/Academic Research/LAI Paper/Feedback Log.md"
    echo "📢 Next: Zé will analyze and propose changes"
    ;;
  
  # Propose changes based on feedback
  propose)
    REVISION_ID="$1"
    echo "🤔 Analyzing feedback and proposing changes..."
    
    # This would involve:
    # 1. Read feedback from log
    # 2. Analyze LaTeX source
    # 3. Generate proposed changes
    # 4. Create revision note
    
    echo "⚠️  This step requires Zé to read feedback and generate proposals"
    echo "Usage: Call Zé with: 'Analyze LAI feedback and propose changes'"
    ;;
  
  # Apply approved changes to LaTeX
  apply)
    echo "✏️  Applying changes to LaTeX source..."
    
    # Check if paper exists
    if [ ! -f "$PAPER_TEX" ]; then
      echo "❌ LaTeX file not found: $PAPER_TEX"
      echo "Please configure PAPER_TEX path in this script"
      exit 1
    fi
    
    # Backup current version
    BACKUP_FILE="${PAPER_TEX}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$PAPER_TEX" "$BACKUP_FILE"
    echo "💾 Backed up to: $BACKUP_FILE"
    
    # Apply changes (would be done by Zé based on proposal)
    echo "⚠️  Changes need to be applied by Zé (edit LaTeX file)"
    echo "Next: Run 'compile' after changes applied"
    ;;
  
  # Compile LaTeX to PDF
  compile)
    echo "🔨 Compiling LaTeX to PDF..."
    
    if [ ! -f "$PAPER_TEX" ]; then
      echo "❌ LaTeX file not found: $PAPER_TEX"
      exit 1
    fi
    
    # Navigate to paper directory
    cd "$PAPER_DIR" || exit 1
    
    # Compile with pdflatex
    pdflatex -interaction=nonstopmode "$(basename "$PAPER_TEX")" 2>&1 | tail -20
    
    if [ $? -eq 0 ] && [ -f "$PAPER_PDF" ]; then
      echo "✅ PDF compiled successfully: $PAPER_PDF"
      echo "Next: Run 'email' to send PDF"
    else
      echo "❌ Compilation failed. Check LaTeX errors above."
      exit 1
    fi
    ;;
  
  # Email PDF
  email)
    RECIPIENT="$1"
    SUBJECT="${2:-LAI Paper - Updated Version}"
    
    if [ -z "$RECIPIENT" ]; then
      echo "Usage: $0 email recipient@example.com [subject]"
      exit 1
    fi
    
    if [ ! -f "$PAPER_PDF" ]; then
      echo "❌ PDF not found: $PAPER_PDF"
      echo "Run 'compile' first"
      exit 1
    fi
    
    echo "📧 Sending PDF to $RECIPIENT..."
    
    # Use Gmail API script
    cd ~/clawd && source venv-google/bin/activate
    python3 scripts/send-email-with-attachment.py \
      --to "$RECIPIENT" \
      --subject "$SUBJECT" \
      --body "Please find attached the updated LAI paper.

Version: $(date '+%Y-%m-%d %H:%M')
Sent by: Zé (automated workflow)

Best regards,
Théo" \
      --attach "$PAPER_PDF"
    
    if [ $? -eq 0 ]; then
      echo "✅ Email sent successfully"
      
      # Update Feedback Log
      echo "📝 Updating feedback log..."
      # (Would mark status as emailed in Obsidian)
    else
      echo "❌ Email failed"
      exit 1
    fi
    ;;
  
  # Full workflow: compile + email
  publish)
    RECIPIENT="$1"
    
    if [ -z "$RECIPIENT" ]; then
      echo "Usage: $0 publish recipient@example.com"
      exit 1
    fi
    
    echo "🚀 Running full publish workflow..."
    
    # Step 1: Compile
    $0 compile
    
    if [ $? -eq 0 ]; then
      # Step 2: Email
      $0 email "$RECIPIENT" "LAI Paper - New Version $(date +%Y-%m-%d)"
    else
      echo "❌ Compilation failed, cannot email"
      exit 1
    fi
    ;;
  
  # Show status
  status)
    echo "📊 LAI Paper Workflow Status"
    echo "=============================="
    echo ""
    echo "LaTeX Source: $PAPER_TEX"
    [ -f "$PAPER_TEX" ] && echo "  ✅ Found" || echo "  ❌ Not found"
    
    echo "PDF Output: $PAPER_PDF"
    [ -f "$PAPER_PDF" ] && echo "  ✅ Found ($(stat -f%z "$PAPER_PDF" 2>/dev/null || stat -c%s "$PAPER_PDF" 2>/dev/null) bytes)" || echo "  ❌ Not found"
    
    echo "Feedback Log: $FEEDBACK_LOG"
    [ -f "$FEEDBACK_LOG" ] && echo "  ✅ Found" || echo "  ❌ Not found"
    
    echo ""
    echo "Recent feedback:"
    grep -A 3 "### \*\*Revision" "$FEEDBACK_LOG" 2>/dev/null | tail -10 || echo "  (none)"
    ;;
  
  *)
    cat << EOF
LAI Paper Workflow Automation

Usage: $0 <command> [args]

Commands:
  feedback <text>        Log feedback from Telegram/Obsidian
  propose <revision>     Analyze feedback and propose changes (via Zé)
  apply                  Apply approved changes to LaTeX source
  compile                Compile LaTeX → PDF
  email <to> [subject]   Email PDF to recipient
  publish <to>           Full workflow: compile + email
  status                 Show current status

Examples:
  $0 feedback "Revise introduction paragraph 2"
  $0 compile
  $0 email supervisor@university.edu
  $0 publish supervisor@university.edu

Configuration:
  Edit this script to set:
  - PAPER_DIR (LaTeX project folder)
  - PAPER_TEX (main .tex file)

EOF
    exit 1
    ;;
esac
