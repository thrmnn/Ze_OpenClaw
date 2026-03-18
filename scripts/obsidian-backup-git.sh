#!/bin/bash
# Automated Git backup for Obsidian vault
# Run daily via cron or manually

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault"
cd "$VAULT_PATH" || exit 1

# Check if git repo exists
if [ ! -d ".git" ]; then
  echo "⚠️  Git not initialized. Run:"
  echo "  cd '$VAULT_PATH'"
  echo "  git init"
  echo "  git remote add origin [your-repo-url]"
  exit 1
fi

# Add all changes
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
  echo "📝 No changes to commit"
  exit 0
fi

# Commit with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "Auto-backup: $TIMESTAMP"

# Push to remote (if configured)
if git remote get-url origin >/dev/null 2>&1; then
  echo "⬆️  Pushing to remote..."
  git push origin main 2>&1 || echo "⚠️  Push failed (check remote config)"
else
  echo "⚠️  No remote configured. Add with:"
  echo "  git remote add origin [your-repo-url]"
fi

echo "✅ Backup complete: $TIMESTAMP"
