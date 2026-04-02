#!/bin/bash
# Obsidian Multi-Vault Helper for WSL
# Usage: obsidian.sh [--vault NAME] <command> [arguments]
# Vaults: research, business, tech, personal (default: personal)

BASE="/home/theo/obsidian-vaults"

# Vault mapping
declare -A VAULTS=(
  [research]="$BASE/Ob_Research_Vault"
  [business]="$BASE/Ob_Business_Vault"
  [tech]="$BASE/Ob_Robotics_Vault"
  [personal]="$BASE/Ob_Perso_Vault"
)

# Default vault
VAULT_NAME="personal"

# Parse --vault flag
if [ "$1" = "--vault" ]; then
  VAULT_NAME="$2"
  shift 2
fi

VAULT_PATH="${VAULTS[$VAULT_NAME]}"
if [ -z "$VAULT_PATH" ]; then
  echo "Unknown vault: $VAULT_NAME"
  echo "Available: ${!VAULTS[*]}"
  exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

search_notes() {
  echo -e "${YELLOW}[$VAULT_NAME] Searching notes for: $1${NC}"
  find "$VAULT_PATH" -name "*.md" -type f ! -path "*/\.obsidian/*" -exec basename {} .md \; | grep -i "$1"
}

search_content() {
  echo -e "${YELLOW}[$VAULT_NAME] Searching content for: $1${NC}"
  grep -r -i --include="*.md" --exclude-dir=".obsidian" "$1" "$VAULT_PATH" | sed "s|$VAULT_PATH/||g"
}

search_all() {
  echo -e "${YELLOW}[ALL VAULTS] Searching content for: $1${NC}"
  for name in "${!VAULTS[@]}"; do
    local path="${VAULTS[$name]}"
    local results=$(grep -r -i --include="*.md" --exclude-dir=".obsidian" "$1" "$path" 2>/dev/null | sed "s|$path/||g")
    if [ -n "$results" ]; then
      echo -e "${GREEN}--- $name ---${NC}"
      echo "$results"
    fi
  done
}

list_notes() {
  echo -e "${YELLOW}[$VAULT_NAME] All notes:${NC}"
  find "$VAULT_PATH" -name "*.md" -type f ! -path "*/\.obsidian/*" | sed "s|$VAULT_PATH/||g" | sort
}

create_note() {
  local note_name="$1"
  local content="${2:-# $note_name\n\nCreated: $(date '+%Y-%m-%d %H:%M')}"
  [[ "$note_name" != *.md ]] && note_name="${note_name}.md"
  local note_path="$VAULT_PATH/$note_name"
  mkdir -p "$(dirname "$note_path")"
  if [ -f "$note_path" ]; then
    echo -e "${YELLOW}Note already exists: $note_name${NC}"
    return 1
  fi
  echo -e "$content" > "$note_path"
  echo -e "${GREEN}[$VAULT_NAME] Created: $note_name${NC}"
}

read_note() {
  local note_name="$1"
  [[ "$note_name" != *.md ]] && note_name="${note_name}.md"
  local note_path="$VAULT_PATH/$note_name"
  if [ ! -f "$note_path" ]; then
    echo -e "${YELLOW}Note not found: $note_name${NC}"
    return 1
  fi
  echo -e "${YELLOW}=== [$VAULT_NAME] $note_name ===${NC}"
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
  echo -e "${GREEN}[$VAULT_NAME] Appended to: $note_name${NC}"
}

show_help() {
  cat << EOF
Obsidian Multi-Vault Helper

Usage: obsidian.sh [--vault NAME] <command> [arguments]

Vaults: research, business, tech, personal (default: personal)

Commands:
  search <query>           Search note names
  search-content <query>   Search note content
  search-all <query>       Search ALL vaults
  list                     List all notes
  create <name> [content]  Create new note
  read <name>              Read note content
  append <name> <content>  Append to existing note
  path                     Show vault path
  vaults                   List all vault paths

Examples:
  obsidian.sh --vault research list
  obsidian.sh --vault business search "AI Agency"
  obsidian.sh search-all "CERN"
  obsidian.sh create "Daily/2026-03-17" "# Today"
EOF
}

case "$1" in
  search)        search_notes "$2" ;;
  search-content) search_content "$2" ;;
  search-all)    search_all "$2" ;;
  list)          list_notes ;;
  create)        create_note "$2" "$3" ;;
  read)          read_note "$2" ;;
  append)        append_note "$2" "$3" ;;
  path)          echo "$VAULT_PATH" ;;
  vaults)
    for name in "${!VAULTS[@]}"; do
      echo "$name: ${VAULTS[$name]}"
    done
    ;;
  *)             show_help; exit 1 ;;
esac
