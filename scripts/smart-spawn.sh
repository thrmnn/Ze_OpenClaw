#!/usr/bin/env bash
# smart-spawn.sh - Intelligent spawn orchestration with rate limit protection
# Usage: smart-spawn.sh <task-description> [agent-label] [task-size]
#
# Task sizes: light (8k), medium (15k), heavy (30k)
# Auto-detects size if not specified

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

RATE_LIMIT_TOKENS=40000  # Tier 1 Anthropic API limit (tokens/min)
SAFE_THRESHOLD=0.75      # Use 75% of rate limit as safe zone
SAFE_TOKENS=$((RATE_LIMIT_TOKENS * 75 / 100))  # 30,000 tokens
BUFFER_TOKENS=5000       # Reserve for main agent

# Task token estimates
declare -A TASK_COSTS=(
    ["light"]=8000
    ["medium"]=15000
    ["heavy"]=30000
)

# ============================================================================
# Helper Functions
# ============================================================================

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Get current session token usage from session_status
get_current_tokens() {
    # Run session_status and extract token usage
    # Format expected: "tokens: 12345/200000"
    local status_output
    status_output=$(openclaw session_status 2>/dev/null || echo "")
    
    if [[ -z "$status_output" ]]; then
        log "WARNING: Could not fetch session status, assuming 0 tokens"
        echo "0"
        return
    fi
    
    # Extract tokens used from status
    # Look for patterns like "tokens: 12345/200000" or "Tokens: 12345"
    local tokens
    tokens=$(echo "$status_output" | grep -oP 'tokens?:\s*\K\d+' | head -1 || echo "0")
    
    echo "$tokens"
}

# Estimate task complexity from description
estimate_task_size() {
    local task="$1"
    local lower_task
    lower_task=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    
    # Heavy tasks: analysis, complex, debug, investigate, refactor
    if [[ "$lower_task" =~ (analysis|analyze|complex|debug|investigate|refactor|optimize) ]]; then
        echo "heavy"
        return
    fi
    
    # Light tasks: test, check, simple, quick, status
    if [[ "$lower_task" =~ (test|check|simple|quick|status|read|list) ]]; then
        echo "light"
        return
    fi
    
    # Default to medium
    echo "medium"
}

# Calculate available token budget
get_available_budget() {
    local current_tokens=$1
    local available=$((SAFE_TOKENS - current_tokens - BUFFER_TOKENS))
    
    # Never return negative
    if [ "$available" -lt 0 ]; then
        echo "0"
    else
        echo "$available"
    fi
}

# Wait for token budget to refresh
wait_for_budget() {
    local required_tokens=$1
    local wait_time=60  # 1 minute for rate limit window to roll
    
    log "Insufficient token budget. Waiting ${wait_time}s for refresh..."
    sleep "$wait_time"
}

# Log spawn decision to Mission Control
log_to_mission_control() {
    local decision="$1"
    local task="$2"
    local tokens_used="$3"
    local tokens_available="$4"
    
    local script_path="$HOME/clawd/scripts/mission-control-log.sh"
    
    if [[ -f "$script_path" ]]; then
        bash "$script_path" \
            "spawn_decision" \
            "Decision: $decision | Task: $task | Used: ${tokens_used}k | Available: ${tokens_available}k" \
            "smart-spawn" \
            2>/dev/null || log "WARNING: Failed to log to Mission Control"
    fi
}

# ============================================================================
# Main Logic
# ============================================================================

main() {
    # Parse arguments
    if [ $# -lt 1 ]; then
        error "Usage: $0 <task-description> [agent-label] [task-size]"
    fi
    
    local task_desc="$1"
    local agent_label="${2:-subagent-$(date +%s)}"
    local task_size="${3:-}"
    
    # Auto-detect task size if not specified
    if [[ -z "$task_size" ]]; then
        task_size=$(estimate_task_size "$task_desc")
        log "Auto-detected task size: $task_size"
    fi
    
    # Validate task size
    if [[ ! "${TASK_COSTS[$task_size]+isset}" ]]; then
        error "Invalid task size: $task_size (must be: light, medium, or heavy)"
    fi
    
    local estimated_cost=${TASK_COSTS[$task_size]}
    
    # Get current token usage
    log "Checking current token budget..."
    local current_tokens
    current_tokens=$(get_current_tokens)
    log "Current session tokens: $current_tokens"
    
    # Calculate available budget
    local available_budget
    available_budget=$(get_available_budget "$current_tokens")
    log "Available token budget: $available_budget (Safe limit: $SAFE_TOKENS)"
    
    # Check if spawn is safe
    if [ "$available_budget" -ge "$estimated_cost" ]; then
        log "✓ Safe to spawn ($estimated_cost tokens < $available_budget available)"
        log_to_mission_control \
            "SPAWN_OK" \
            "$task_desc" \
            "$((estimated_cost / 1000))" \
            "$((available_budget / 1000))"
        
        # Spawn the agent
        log "Spawning agent: $agent_label"
        openclaw spawn --label "$agent_label" --task "$task_desc"
        
        log "✓ Agent spawned successfully"
        exit 0
    else
        log "⚠ Insufficient budget ($estimated_cost tokens > $available_budget available)"
        log_to_mission_control \
            "WAIT_BUDGET" \
            "$task_desc" \
            "$((estimated_cost / 1000))" \
            "$((available_budget / 1000))"
        
        # Wait for budget refresh
        wait_for_budget "$estimated_cost"
        
        # Retry after wait
        log "Retrying spawn after budget refresh..."
        openclaw spawn --label "$agent_label" --task "$task_desc"
        
        log "✓ Agent spawned successfully (after wait)"
        exit 0
    fi
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
