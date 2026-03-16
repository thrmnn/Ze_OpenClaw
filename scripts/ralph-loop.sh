#!/bin/bash
# ralph-loop.sh - Autonomous Task Orchestration Loop
# Continuously monitors Trello and spawns agents for high-priority tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-config.sh"
source "$SCRIPT_DIR/token-utils.sh"

# Trello credentials
source "$HOME/clawd/credentials/trello.env"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${msg}" | tee -a "$RALPH_LOG_FILE"
}

# Mission Control logging
mc_log() {
    if [[ "$RALPH_MC_ENABLED" == "true" ]]; then
        bash "$SCRIPT_DIR/mission-control-log.sh" "$@" 2>/dev/null || true
    fi
}

# Initialize state files
init_state() {
    if [[ ! -f "$RALPH_STATE_FILE" ]]; then
        echo '{"loop_count": 0, "last_run": null, "total_spawns": 0}' > "$RALPH_STATE_FILE"
    fi
    
    if [[ ! -f "$RALPH_ACTIVE_SPAWNS" ]]; then
        echo '[]' > "$RALPH_ACTIVE_SPAWNS"
    fi
}

# Check for control cards
check_control_cards() {
    local cards=$(curl -s "https://api.trello.com/1/boards/${RALPH_BOARD_ID}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}")
    
    if echo "$cards" | jq -e ".[] | select(.name == \"$RALPH_PAUSE_CARD\")" > /dev/null; then
        log "WARN" "${YELLOW}PAUSE card detected - waiting...${NC}"
        return 1
    fi
    
    if echo "$cards" | jq -e ".[] | select(.name == \"$RALPH_STOP_CARD\")" > /dev/null; then
        log "INFO" "${RED}STOP card detected - shutting down${NC}"
        exit 0
    fi
    
    return 0
}

# Get active spawn count
get_active_spawn_count() {
    openclaw sessions list --json 2>/dev/null | \
        jq '[.[] | select(.kind == "spawn" and .status == "active")] | length' || echo "0"
}

# Get sprint tasks from Trello
get_sprint_tasks() {
    # Get list ID for Current Sprint
    local lists=$(curl -s "https://api.trello.com/1/boards/${RALPH_BOARD_ID}/lists?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}")
    local sprint_list_id=$(echo "$lists" | jq -r ".[] | select(.name == \"$RALPH_SPRINT_LIST\") | .id")
    
    if [[ -z "$sprint_list_id" || "$sprint_list_id" == "null" ]]; then
        log "ERROR" "Sprint list not found: $RALPH_SPRINT_LIST"
        return 1
    fi
    
    # Get cards from sprint list
    curl -s "https://api.trello.com/1/lists/${sprint_list_id}/cards?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}"
}

# Filter and prioritize tasks
prioritize_tasks() {
    local tasks="$1"
    
    # Filter out already-worked cards (with Ralph label)
    # Prioritize by: 1) priority keywords, 2) due date, 3) position
    echo "$tasks" | jq -r '
        map(select(
            (.labels | map(.name) | any(. == "🤖 Ralph") | not) and
            (.name | test("'"$RALPH_SKIP_KEYWORDS"'"; "i") | not)
        )) |
        sort_by(
            if (.name | test("'"$RALPH_PRIORITY_KEYWORDS"'"; "i")) then 0 else 1 end,
            .due // "9999-12-31",
            .pos
        )
    '
}

# Create spawn for task
spawn_for_task() {
    local card_id="$1"
    local card_name="$2"
    local card_desc="$3"
    
    log "INFO" "${GREEN}Spawning agent for: ${card_name}${NC}"
    
    # Build task prompt
    local task_prompt="Complete Trello task: ${card_name}

Description:
${card_desc}

Instructions:
1. Analyze the task requirements
2. Break down into subtasks if needed
3. Execute the work
4. Update the Trello card with progress
5. Move to 'Done' when complete

Card ID: ${card_id}
Use Trello API to update progress."
    
    # Use smart-spawn for safe spawning
    local spawn_result=$(bash "$SCRIPT_DIR/smart-spawn.sh" "$task_prompt" "ralph-worker" 2>&1)
    
    if echo "$spawn_result" | grep -q "SPAWN_OK"; then
        # Add Ralph label to card
        add_ralph_label "$card_id"
        
        # Track spawn
        local spawn_id=$(echo "$spawn_result" | grep -oP 'sessionId: \K[a-f0-9-]+' || echo "unknown")
        track_spawn "$spawn_id" "$card_id" "$card_name"
        
        log "INFO" "Spawned agent: $spawn_id for card: $card_name"
        mc_log "Ralph spawned agent for: $card_name" "ralph_spawn"
        return 0
    else
        log "WARN" "Failed to spawn for: $card_name - $spawn_result"
        return 1
    fi
}

# Add Ralph label to card
add_ralph_label() {
    local card_id="$1"
    
    # Get or create Ralph label
    local labels=$(curl -s "https://api.trello.com/1/boards/${RALPH_BOARD_ID}/labels?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}")
    local ralph_label_id=$(echo "$labels" | jq -r ".[] | select(.name == \"$RALPH_AUTO_LABEL\") | .id")
    
    if [[ -z "$ralph_label_id" || "$ralph_label_id" == "null" ]]; then
        # Create label
        ralph_label_id=$(curl -s -X POST "https://api.trello.com/1/labels" \
            -d "key=${TRELLO_API_KEY}" \
            -d "token=${TRELLO_TOKEN}" \
            -d "name=$RALPH_AUTO_LABEL" \
            -d "color=blue" \
            -d "idBoard=${RALPH_BOARD_ID}" | jq -r '.id')
    fi
    
    # Add label to card
    curl -s -X POST "https://api.trello.com/1/cards/${card_id}/idLabels" \
        -d "key=${TRELLO_API_KEY}" \
        -d "token=${TRELLO_TOKEN}" \
        -d "value=${ralph_label_id}" > /dev/null
}

# Track spawn in state file
track_spawn() {
    local spawn_id="$1"
    local card_id="$2"
    local card_name="$3"
    
    local spawn_entry=$(jq -n \
        --arg id "$spawn_id" \
        --arg card "$card_id" \
        --arg name "$card_name" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{session_id: $id, card_id: $card, card_name: $name, started_at: $ts, status: "active"}')
    
    jq ". += [$spawn_entry]" "$RALPH_ACTIVE_SPAWNS" > "${RALPH_ACTIVE_SPAWNS}.tmp"
    mv "${RALPH_ACTIVE_SPAWNS}.tmp" "$RALPH_ACTIVE_SPAWNS"
}

# Clean up completed spawns
cleanup_spawns() {
    local active_sessions=$(openclaw sessions list --json 2>/dev/null | jq -r '[.[] | select(.kind == "spawn") | .sessionId] | join(",")')
    
    if [[ -z "$active_sessions" ]]; then
        # No active spawns, clear file
        echo '[]' > "$RALPH_ACTIVE_SPAWNS"
        return
    fi
    
    # Keep only spawns that are still active
    jq --arg active "$active_sessions" '
        map(select(.status == "active" and ($active | split(",") | any(. == .session_id))))
    ' "$RALPH_ACTIVE_SPAWNS" > "${RALPH_ACTIVE_SPAWNS}.tmp"
    mv "${RALPH_ACTIVE_SPAWNS}.tmp" "$RALPH_ACTIVE_SPAWNS"
}

# Main loop iteration
loop_iteration() {
    log "INFO" "${BLUE}=== Ralph Loop Iteration ===${NC}"
    
    # Check control cards
    if ! check_control_cards; then
        return 0
    fi
    
    # Clean up completed spawns
    cleanup_spawns
    
    # Check active spawn count
    local active_count=$(get_active_spawn_count)
    log "INFO" "Active spawns: $active_count / $RALPH_MAX_CONCURRENT"
    
    if [[ $active_count -ge $RALPH_MAX_CONCURRENT ]]; then
        log "INFO" "Max concurrent agents reached - waiting"
        mc_log "Ralph waiting: max concurrent agents ($RALPH_MAX_CONCURRENT)" "ralph_wait"
        return 0
    fi
    
    # Check token budget
    local budget_report=$(get_budget_report 2>/dev/null || echo '{"available": 25000}')
    local available=$(echo "$budget_report" | jq -r '.available // 25000')
    
    # Validate available is a number
    if ! [[ "$available" =~ ^[0-9]+$ ]]; then
        log "WARN" "${YELLOW}Failed to parse token budget - assuming safe (25k)${NC}"
        available=25000
    fi
    
    if [[ $available -lt 8000 ]]; then
        log "WARN" "${YELLOW}Low token budget: ${available} - waiting${NC}"
        mc_log "Ralph waiting: low token budget (${available})" "ralph_budget"
        sleep 60
        return 0
    fi
    
    # Get sprint tasks
    local tasks=$(get_sprint_tasks)
    if [[ -z "$tasks" || "$tasks" == "[]" ]]; then
        log "INFO" "No tasks in sprint - idling"
        return 0
    fi
    
    # Prioritize tasks
    local prioritized=$(prioritize_tasks "$tasks")
    local task_count=$(echo "$prioritized" | jq 'length')
    
    log "INFO" "Found $task_count available tasks"
    
    if [[ $task_count -eq 0 ]]; then
        log "INFO" "No unassigned tasks - idling"
        return 0
    fi
    
    # Spawn for top priority task
    local top_task=$(echo "$prioritized" | jq -r '.[0]')
    local card_id=$(echo "$top_task" | jq -r '.id')
    local card_name=$(echo "$top_task" | jq -r '.name')
    local card_desc=$(echo "$top_task" | jq -r '.desc // ""')
    
    spawn_for_task "$card_id" "$card_name" "$card_desc"
    
    # Update state
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.loop_count += 1 | .last_run = $ts | .total_spawns += 1' \
       "$RALPH_STATE_FILE" > "${RALPH_STATE_FILE}.tmp"
    mv "${RALPH_STATE_FILE}.tmp" "$RALPH_STATE_FILE"
}

# Main loop
main() {
    log "INFO" "${GREEN}=== Ralph Loop Starting ===${NC}"
    mc_log "Ralph Loop started" "ralph_start"
    
    init_state
    
    trap 'log "INFO" "Ralph Loop stopped"; mc_log "Ralph Loop stopped" "ralph_stop"; exit 0' SIGINT SIGTERM
    
    while true; do
        loop_iteration || true
        
        log "INFO" "Sleeping for ${RALPH_MIN_LOOP_DELAY}s..."
        sleep "$RALPH_MIN_LOOP_DELAY"
    done
}

# Run main loop
main "$@"
