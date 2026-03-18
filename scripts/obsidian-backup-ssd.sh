#!/bin/bash
# Physical SSD backup for Obsidian vault
# Run weekly for redundancy

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault"
BACKUP_BASE="/mnt/e/Backups/Obsidian"  # Adjust to your SSD mount point
TIMESTAMP=$(date '+%Y-%m-%d_%H%M')
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"

# Check if backup drive is mounted
if [ ! -d "/mnt/e" ]; then
  echo "⚠️  Backup drive not mounted at /mnt/e"
  echo "Available drives:"
  ls -d /mnt/* 2>/dev/null || echo "No drives found"
  exit 1
fi

# Create backup base directory if needed
mkdir -p "$BACKUP_BASE"

echo "📦 Starting backup..."
echo "Source: $VAULT_PATH"
echo "Destination: $BACKUP_DIR"

# Rsync with archive mode (preserves permissions, timestamps)
rsync -av --delete \
  --exclude='.git/' \
  --exclude='.obsidian/workspace*' \
  --exclude='.trash/' \
  "$VAULT_PATH/" \
  "$BACKUP_DIR/" 2>&1

if [ $? -eq 0 ]; then
  echo "✅ Backup complete: $BACKUP_DIR"
  
  # Keep only last 4 weekly backups (1 month)
  echo "🧹 Cleaning old backups (keeping last 4)..."
  ls -dt "$BACKUP_BASE"/*/ | tail -n +5 | xargs rm -rf 2>/dev/null
  echo "Remaining backups:"
  ls -lth "$BACKUP_BASE" | head -5
else
  echo "❌ Backup failed"
  exit 1
fi
