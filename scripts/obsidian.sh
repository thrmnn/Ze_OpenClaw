#!/bin/bash
# Obsidian Vault Helper for WSL
# Direct file operations for Obsidian vault

VAULT_PATH="/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

search_notes() {
  echo -e "${YELLOW}Searching notes for: $1${NC}"
  find "$VAULT_PATH" -name "*.md" -type f ! -path "*/\.obsidian/*" -exec basename {} .md \; | grep -i "$1"
}

search_content() {
  echo -e "${YELLOW}Searching content for: $1${NC}"
  grep -r -i --include="*.md" --exclude-dir=".obsidian" "$1" "$VAULT_PATH" | sed "s|$VAULT_PATH/||g"
}

list_notes() {
  echo -e "${YELLOW}All notes in vault:${NC}"
  find "$VAULT_PATH" -name "*.md" -type f ! -path "*/\.obsidian/*" | sed "s|$VAULT_PATH/||g" | sort
}

create_note() {
  local note_name="$1"
  local content="${2:-# $note_name\n\nCreated: $(date '+%Y-%m-%d %H:%M')}"
  
  # Ensure .md extension
  [[ "$note_name" != *.md ]] && note_name="${note_name}.md"
  
  local note_path="$VAULT_PATH/$note_name"
  local note_dir=$(dirname "$note_path")
  
  # Create directory if needed
  mkdir -p "$note_dir"
  
  if [ -f "$note_path" ]; then
    echo -e "${YELLOW}Note already exists: $note_name${NC}"
    return 1
  fi
  
  echo -e "$content" > "$note_path"
  echo -e "${GREEN}Created: $note_name${NC}"
}

read_note() {
  local note_name="$1"
  [[ "$note_name" != *.md ]] && note_name="${note_name}.md"
  
  local note_path="$VAULT_PATH/$note_name"
  
  if [ ! -f "$note_path" ]; then
    echo -e "${YELLOW}Note not found: $note_name${NC}"
    return 1
  fi
  
  echo -e "${YELLOW}=== $note_name ===${NC}"
  cat "$note_path"
}

append_note() {
  local note_name="$1"
  local content="$2"
  [[ "$note_name" != *.md ]] && note_name="${note_name}.md"
  
  local note_path="$VAULT_PATH/$note_name"
  
  if [ ! -f "$note_path" ]; then
    echo -e "${YELLOW}Note not found: $note_name${NC}"
    return 1
  fi
  
  echo -e "\n$content" >> "$note_path"
  echo -e "${GREEN}Appended to: $note_name${NC}"
}

show_help() {
  cat << EOF
Obsidian Vault Helper

Usage: obsidian.sh <command> [arguments]

Commands:
  search <query>           Search note names
  search-content <query>   Search note content (grep)
  list                     List all notes
  create <name> [content]  Create new note
  read <name>              Read note content
  append <name> <content>  Append to existing note
  path                     Show vault path
  
Examples:
  obsidian.sh search "meeting"
  obsidian.sh search-content "todo"
  obsidian.sh create "Daily/2026-03-14" "# Today's tasks"
  obsidian.sh read "Welcome"
  obsidian.sh append "Welcome" "New paragraph"
EOF
}

# Main command handler
case "$1" in
  search)
    search_notes "$2"
    ;;
  search-content)
    search_content "$2"
    ;;
  list)
    list_notes
    ;;
  create)
    create_note "$2" "$3"
    ;;
  read)
    read_note "$2"
    ;;
  append)
    append_note "$2" "$3"
    ;;
  path)
    echo "$VAULT_PATH"
    ;;
  *)
    show_help
    exit 1
    ;;
esac
