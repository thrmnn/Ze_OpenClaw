#!/bin/bash
# Zé Dashboard - At-a-glance workspace status

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Header
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          🤖 Zé Dashboard              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo -e "Date: $(date '+%Y-%m-%d %H:%M')"
    echo -e "Location: ${BLUE}~/clawd${NC}"
    echo ""
}

# Current Focus
show_focus() {
    echo -e "${YELLOW}🎯 Today's Focus:${NC}"
    
    # Try to read from Obsidian daily note
    TODAY=$(date +%Y-%m-%d)
    DAILY_NOTE="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault/Daily/$TODAY.md"
    
    if [[ -f "$DAILY_NOTE" ]]; then
        # Extract top 3 incomplete tasks
        grep -E '^\s*- \[ \]' "$DAILY_NOTE" 2>/dev/null | head -3 | sed 's/^[[:space:]]*- \[ \] /  • /' || echo "  No tasks found"
    else
        echo "  [AI Agency] Build MVP - Day 1"
        echo "  [Website] Add project photos"
        echo "  [Job Pipeline] Fix OAuth"
    fi
    echo ""
}

# Active Projects
show_projects() {
    echo -e "${BLUE}📂 Active Projects:${NC}"
    echo "  AI Agency        Week 1/12   🔴 Planning"
    echo "  Personal Website   70% done   🟢 Content ready"
    echo "  Mission Control    Deployed   ✅ Complete"
    echo "  Job Pipeline       Blocked    🔴 OAuth issue"
    echo ""
}

# Recent Git Activity
show_git() {
    echo -e "${GREEN}📝 Recent Work (last 5 commits):${NC}"
    cd ~/clawd 2>/dev/null
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git log --oneline --graph --decorate -5 --color=always 2>/dev/null | sed 's/^/  /'
    else
        echo "  No git history available"
    fi
    echo ""
}

# Upcoming Deadlines
show_deadlines() {
    echo -e "${YELLOW}⏰ Upcoming Deadlines:${NC}"
    
    # Calculate days
    TODAY_EPOCH=$(date +%s)
    END_MARCH=$(date -d "2026-03-31" +%s 2>/dev/null || echo "0")
    JUNE=$(date -d "2026-06-30" +%s 2>/dev/null || echo "0")
    
    if [[ "$END_MARCH" != "0" ]]; then
        DAYS_WEBSITE=$(( ($END_MARCH - $TODAY_EPOCH) / 86400 ))
        echo "  Personal Website  ${DAYS_WEBSITE} days  (End of March)"
        echo "  LAI Paper         ${DAYS_WEBSITE} days  (March 2026)"
    fi
    
    if [[ "$JUNE" != "0" ]]; then
        DAYS_BRISA=$(( ($JUNE - $TODAY_EPOCH) / 86400 ))
        echo "  Brisa+ Paper      ${DAYS_BRISA} days (June 2026)"
    fi
    echo ""
}

# Token Usage (if available)
show_tokens() {
    echo -e "${CYAN}🎫 Session Info:${NC}"
    
    # Check if OPENCLAW_SESSION_ID exists (indicates we're in OpenClaw)
    if [[ -n "$OPENCLAW_SESSION_ID" ]]; then
        echo "  Session: $OPENCLAW_SESSION_ID"
        echo "  Model: anthropic/claude-sonnet-4-5"
    else
        echo "  Running outside OpenClaw session"
    fi
    
    # Show clawd git status
    cd ~/clawd 2>/dev/null
    if git rev-parse --git-dir > /dev/null 2>&1; then
        CHANGES=$(git status --porcelain | wc -l)
        if [[ $CHANGES -gt 0 ]]; then
            echo "  ⚠️  ${CHANGES} uncommitted change(s)"
        else
            echo "  ✅ Workspace clean"
        fi
    fi
    echo ""
}

# Quick Actions
show_actions() {
    echo -e "${GREEN}💡 Quick Actions:${NC}"
    echo "  ${BLUE}otd${NC}      - Run /today command"
    echo "  ${BLUE}aar${NC}      - View AI Agency roadmap"
    echo "  ${BLUE}glog${NC}     - Recent commits"
    echo "  ${BLUE}osync${NC}    - Backup Obsidian"
    echo "  ${BLUE}aiagency${NC} - Go to AI Agency project"
    echo ""
}

# Main
main() {
    show_header
    show_focus
    show_projects
    show_git
    show_deadlines
    show_tokens
    show_actions
}

main
