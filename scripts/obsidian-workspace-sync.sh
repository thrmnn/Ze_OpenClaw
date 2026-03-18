#!/usr/bin/env bash
# obsidian-workspace-sync.sh - Bidirectional Obsidian ↔ workspace sync
# Usage: ./obsidian-workspace-sync.sh [pull|push]

set -euo pipefail

# Configuration
OBSIDIAN_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Business_Vault/Projects/AI Agency"
WORKSPACE_PATH="$HOME/projects/ai-agency/docs"
LOG_FILE="$HOME/clawd/logs/obsidian-sync.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Error handling
error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    log "ERROR: $*"
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}✓ $*${NC}"
    log "SUCCESS: $*"
}

# Warning message
warn() {
    echo -e "${YELLOW}⚠ $*${NC}"
    log "WARNING: $*"
}

# Validate paths
validate_paths() {
    if [[ ! -d "$OBSIDIAN_PATH" ]]; then
        error "Obsidian path not found: $OBSIDIAN_PATH"
    fi
    
    # Create workspace path if it doesn't exist
    if [[ ! -d "$WORKSPACE_PATH" ]]; then
        warn "Workspace path doesn't exist, creating: $WORKSPACE_PATH"
        mkdir -p "$WORKSPACE_PATH" || error "Failed to create workspace directory"
    fi
}

# Show sync preview
show_preview() {
    local direction=$1
    local src=$2
    local dst=$3
    
    echo -e "\n${YELLOW}Sync Preview (${direction}):${NC}"
    echo "Source: $src"
    echo "Destination: $dst"
    echo ""
    
    # Show what would be synced (dry-run)
    rsync -avh --update --dry-run "$src/" "$dst/" 2>/dev/null | grep -E '^\.' || echo "  (No changes detected)"
    echo ""
}

# Perform sync
sync_files() {
    local direction=$1
    local src=$2
    local dst=$3
    
    log "Starting sync: $direction"
    log "Source: $src"
    log "Destination: $dst"
    
    # rsync options:
    # -a: archive mode (preserves timestamps, permissions, etc.)
    # -v: verbose
    # -h: human-readable sizes
    # --update: skip files that are newer on the destination
    # --delete: remove files from dst that don't exist in src (optional, commented out for safety)
    # --exclude: skip certain files/folders
    
    rsync -avh \
        --update \
        --exclude='.obsidian/' \
        --exclude='.trash/' \
        --exclude='.git/' \
        --exclude='*.tmp' \
        --exclude='.DS_Store' \
        "$src/" "$dst/" 2>&1 | tee -a "$LOG_FILE"
    
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        success "Sync completed: $direction"
    else
        error "Sync failed: $direction"
    fi
}

# Pull: Obsidian → workspace
pull() {
    log "=== PULL MODE: Obsidian → workspace ==="
    validate_paths
    show_preview "PULL" "$OBSIDIAN_PATH" "$WORKSPACE_PATH"
    sync_files "PULL" "$OBSIDIAN_PATH" "$WORKSPACE_PATH"
}

# Push: workspace → Obsidian
push() {
    log "=== PUSH MODE: workspace → Obsidian ==="
    validate_paths
    show_preview "PUSH" "$WORKSPACE_PATH" "$OBSIDIAN_PATH"
    sync_files "PUSH" "$WORKSPACE_PATH" "$OBSIDIAN_PATH"
}

# Show usage
usage() {
    cat << EOF
Usage: $0 [pull|push]

Modes:
  pull    Sync from Obsidian to workspace (morning sync)
  push    Sync from workspace to Obsidian (evening sync)

Examples:
  $0 pull     # Get latest from Obsidian
  $0 push     # Send updates to Obsidian

Paths:
  Obsidian: $OBSIDIAN_PATH
  Workspace: $WORKSPACE_PATH
  Log: $LOG_FILE
EOF
    exit 1
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi
    
    case "${1:-}" in
        pull)
            pull
            ;;
        push)
            push
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
