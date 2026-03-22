#!/bin/bash
# Trello Quick Actions - Helper functions

set -e
source ~/clawd/credentials/trello.env

BOARD_ID="699dc91ad27a2301f3acc5f1"  # Zé Dashboard
NOW_LIST_ID="699dc91ad27a2301f3acc5e5"  # Current Sprint
DONE_LIST_ID="699dc91ad27a2301f3acc5e4"  # Done

function get_card_id() {
    local search="$1"
    curl -s "https://api.trello.com/1/boards/${BOARD_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" | \
        jq -r ".[] | select(.name | test(\"${search}\"; \"i\")) | .id" | head -1
}

function move_to_done() {
    local search="$1"
    local card_id=$(get_card_id "$search")
    
    if [ -z "$card_id" ]; then
        echo "❌ Card not found: $search"
        exit 1
    fi
    
    curl -s -X PUT "https://api.trello.com/1/cards/${card_id}?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" \
        -d "idList=${DONE_LIST_ID}" > /dev/null
    
    echo "✅ Moved to Done: $search"
}

function add_card() {
    local name="$1"
    local desc="${2:-}"
    
    result=$(curl -s -X POST "https://api.trello.com/1/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" \
        -d "idList=${NOW_LIST_ID}" \
        -d "name=${name}" \
        -d "desc=${desc}")
    
    echo "✅ Created card: $name"
}

function add_description() {
    local search="$1"
    local desc="$2"
    local card_id=$(get_card_id "$search")
    
    if [ -z "$card_id" ]; then
        echo "❌ Card not found: $search"
        exit 1
    fi
    
    curl -s -X PUT "https://api.trello.com/1/cards/${card_id}?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" \
        -d "desc=${desc}" > /dev/null
    
    echo "✅ Added description to: $search"
}

# Parse command
case "$1" in
    done)
        shift
        move_to_done "$*"
        ;;
    add)
        shift
        add_card "$*"
        ;;
    describe)
        card="$2"
        shift 2
        add_description "$card" "$*"
        ;;
    *)
        echo "Usage:"
        echo "  trello-quick-actions.sh done <card-name>"
        echo "  trello-quick-actions.sh add <card-name>"
        echo "  trello-quick-actions.sh describe <card-name> <description>"
        exit 1
        ;;
esac
