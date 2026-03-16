#!/bin/bash
# LAI Paper - Safety Protocols
# CRITICAL: Academic integrity and version control

PAPER_REPO="/home/theo/lai_paper"

# Safety check before ANY modification
safety_check() {
  echo "🔒 Running safety checks..."
  
  cd "$PAPER_REPO" || exit 1
  
  # Check 1: Clean working directory
  if ! git diff-index --quiet HEAD --; then
    echo "⚠️  WARNING: Uncommitted changes detected"
    git status --short
    echo ""
    echo "Commit these changes before proceeding? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
      git add -A
      git commit -m "WIP: Save before automated changes"
      git push origin main
    else
      echo "❌ Aborting - commit changes manually first"
      exit 1
    fi
  fi
  
  # Check 2: Synced with remote
  LOCAL=$(git rev-parse @)
  REMOTE=$(git rev-parse @{u} 2>/dev/null)
  
  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "⚠️  WARNING: Local and remote are out of sync"
    echo "Pull latest changes? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
      git pull --rebase origin main
    else
      echo "❌ Aborting - sync with remote first"
      exit 1
    fi
  fi
  
  echo "✅ Safety checks passed"
}

# Create backup before edit
create_backup() {
  local file="$1"
  local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
  
  cp "$file" "$backup"
  echo "💾 Backup created: $backup"
}

# Commit changes with detailed message
commit_change() {
  local change_type="$1"  # e.g., "feedback-revision", "typo-fix", "structure-change"
  local description="$2"
  
  cd "$PAPER_REPO" || exit 1
  
  git add -A
  git commit -m "[$change_type] $description

Automated via Zé LAI workflow
Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
Approved by: Théo"
  
  echo "📝 Committed: $description"
}

# Push to GitHub
sync_github() {
  cd "$PAPER_REPO" || exit 1
  
  echo "⬆️  Syncing with GitHub..."
  git push origin main
  
  if [ $? -eq 0 ]; then
    echo "✅ Synced successfully"
  else
    echo "❌ Sync failed - check connection and credentials"
    exit 1
  fi
}

# Show diff before applying
show_diff() {
  local file="$1"
  
  cd "$PAPER_REPO" || exit 1
  
  echo "📊 Changes to be made:"
  echo "===================="
  git diff "$file" || echo "New file, no diff available"
  echo "===================="
  echo ""
  echo "Approve these changes? (y/n)"
}

# Main safety workflow
case "$1" in
  check)
    safety_check
    ;;
  backup)
    create_backup "$2"
    ;;
  commit)
    commit_change "$2" "$3"
    ;;
  sync)
    sync_github
    ;;
  diff)
    show_diff "$2"
    ;;
  *)
    echo "LAI Paper Safety Protocols"
    echo ""
    echo "Usage:"
    echo "  $0 check           Run pre-modification safety checks"
    echo "  $0 backup <file>   Create timestamped backup"
    echo "  $0 commit <type> <description>  Commit with structured message"
    echo "  $0 sync            Push to GitHub"
    echo "  $0 diff <file>     Show pending changes"
    ;;
esac
