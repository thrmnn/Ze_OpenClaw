#!/bin/bash
# Backup important OpenClaw config and state before reinstall
# Run from: /home/theo/clawd

set -e

BACKUP_DIR="$HOME/clawd-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Backing up OpenClaw to: $BACKUP_DIR"

# OpenClaw config and credentials
echo "  → OpenClaw config..."
cp -r ~/.openclaw/openclaw.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.openclaw/.env "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.openclaw/credentials "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.openclaw/identity "$BACKUP_DIR/" 2>/dev/null || true

# Clawd workspace (important files only)
echo "  → Clawd workspace (important files)..."
mkdir -p "$BACKUP_DIR/clawd"
cp -r ~/clawd/{AGENTS.md,SOUL.md,USER.md,MEMORY.md,TOOLS.md,HEARTBEAT.md} "$BACKUP_DIR/clawd/" 2>/dev/null || true
cp -r ~/clawd/memory "$BACKUP_DIR/clawd/" 2>/dev/null || true
cp -r ~/clawd/credentials "$BACKUP_DIR/clawd/" 2>/dev/null || true
cp -r ~/clawd/scripts "$BACKUP_DIR/clawd/" 2>/dev/null || true

# Systemd service files
echo "  → Systemd services..."
cp ~/.config/systemd/user/openclaw-gateway.service "$BACKUP_DIR/" 2>/dev/null || true
cp ~/.config/systemd/user/clawdbot-gateway.service "$BACKUP_DIR/" 2>/dev/null || true

echo ""
echo "✅ Backup complete: $BACKUP_DIR"
echo ""
echo "To restore after reinstall:"
echo "  cp $BACKUP_DIR/openclaw.json ~/.openclaw/"
echo "  cp -r $BACKUP_DIR/credentials ~/.openclaw/"
echo "  cp -r $BACKUP_DIR/identity ~/.openclaw/"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user restart openclaw-gateway.service"
