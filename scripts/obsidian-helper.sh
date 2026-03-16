#!/bin/bash
# Obsidian helper script for WSL
# Auto-switches to vault directory for operations

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault"

case "$1" in
  search|search-content)
    obsidian "$@"
    ;;
  create|move|delete|list)
    cd "$VAULT_PATH" && obsidian "$@"
    ;;
  path)
    echo "$VAULT_PATH"
    ;;
  list-notes)
    find "$VAULT_PATH" -name "*.md" -type f | sed "s|$VAULT_PATH/||g" | grep -v "^\.obsidian"
    ;;
  *)
    echo "Usage: obsidian-helper.sh {search|search-content|create|move|delete|list|path|list-notes}"
    echo ""
    echo "Examples:"
    echo "  obsidian-helper.sh search 'query'"
    echo "  obsidian-helper.sh search-content 'text'"
    echo "  obsidian-helper.sh create 'New Note' --content 'Content here'"
    echo "  obsidian-helper.sh list-notes"
    echo "  obsidian-helper.sh path"
    exit 1
    ;;
esac
