#!/usr/bin/env bash
# token-utils.sh - Token budget utility functions
# Source this file in other scripts: source ~/clawd/scripts/token-utils.sh

# ============================================================================
# Configuration
# ============================================================================

RATE_LIMIT_TOKENS=40000  # Tier 1 Anthropic API limit (tokens/min)
SAFE_THRESHOLD=0.75      # Use 75% of rate limit as safe zone
SAFE_TOKENS=$((RATE_LIMIT_TOKENS * 75 / 100))  # 30,000 tokens
BUFFER_TOKENS=5000       # Reserve for main agent

# ============================================================================
# Token Utility Functions
# ============================================================================

# Get current session token usage
# Returns: integer (tokens used in current session)
get_current_tokens() {
    local status_output
    status_output=$(openclaw session_status 2>/dev/null || echo "")
    
    if [[ -z "$status_output" ]]; then
        echo "0"
        return
    fi
    
    # Extract tokens used from status
    # Look for patterns like "tokens: 12345/200000" or "Tokens: 12345"
    local tokens
    tokens=$(echo "$status_output" | grep -oP 'tokens?:\s*\K\d+' | head -1 || echo "0")
    
    echo "$tokens"
}

# Calculate available token budget
# Args: $1 - current tokens used (optional, fetches if not provided)
# Returns: integer (available tokens)
get_available_budget() {
    local current_tokens="${1:-}"
    
    if [[ -z "$current_tokens" ]]; then
        current_tokens=$(get_current_tokens)
    fi
    
    local available=$((SAFE_TOKENS - current_tokens - BUFFER_TOKENS))
    
    # Never return negative
    if [ "$available" -lt 0 ]; then
        echo "0"
    else
        echo "$available"
    fi
}

# Check if spawn is safe for given token cost
# Args: $1 - estimated token cost
# Returns: 0 (true) if safe, 1 (false) if not safe
is_spawn_safe() {
    local estimated_cost="$1"
    local available_budget
    available_budget=$(get_available_budget)
    
    if [ "$available_budget" -ge "$estimated_cost" ]; then
        return 0  # Safe
    else
        return 1  # Not safe
    fi
}

# Get token budget status as human-readable string
# Returns: string with budget info
get_budget_status() {
    local current_tokens
    local available_budget
    local usage_percent
    
    current_tokens=$(get_current_tokens)
    available_budget=$(get_available_budget "$current_tokens")
    usage_percent=$((current_tokens * 100 / RATE_LIMIT_TOKENS))
    
    echo "Current: ${current_tokens} tokens | Available: ${available_budget} tokens | Usage: ${usage_percent}% of rate limit"
}

# Format tokens as human-readable (k for thousands)
# Args: $1 - token count
# Returns: string (e.g., "15k" or "1.2k")
format_tokens() {
    local tokens="$1"
    
    if [ "$tokens" -ge 1000 ]; then
        local k=$((tokens / 1000))
        local remainder=$((tokens % 1000))
        
        if [ "$remainder" -ge 100 ]; then
            local decimal=$((remainder / 100))
            echo "${k}.${decimal}k"
        else
            echo "${k}k"
        fi
    else
        echo "$tokens"
    fi
}

# Calculate recommended wait time before spawn
# Args: $1 - estimated token cost
# Returns: integer (seconds to wait, 0 if safe to spawn now)
get_wait_time() {
    local estimated_cost="$1"
    local available_budget
    available_budget=$(get_available_budget)
    
    if [ "$available_budget" -ge "$estimated_cost" ]; then
        echo "0"  # No wait needed
        return
    fi
    
    # Need to wait for rate limit window to roll (60 seconds)
    echo "60"
}

# Print token budget report
# Useful for debugging and monitoring
print_budget_report() {
    local current_tokens
    local available_budget
    local usage_percent
    
    current_tokens=$(get_current_tokens)
    available_budget=$(get_available_budget "$current_tokens")
    usage_percent=$((current_tokens * 100 / RATE_LIMIT_TOKENS))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Token Budget Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Rate Limit:      $(format_tokens $RATE_LIMIT_TOKENS) tokens/min"
    echo "Safe Threshold:  $(format_tokens $SAFE_TOKENS) tokens (${SAFE_THRESHOLD})"
    echo "Buffer:          $(format_tokens $BUFFER_TOKENS) tokens"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Current Usage:   $(format_tokens $current_tokens) tokens (${usage_percent}%)"
    echo "Available:       $(format_tokens $available_budget) tokens"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Task capacity
    echo "Spawn Capacity:"
    echo "  Light (8k):    $((available_budget / 8000)) agents"
    echo "  Medium (15k):  $((available_budget / 15000)) agents"
    echo "  Heavy (30k):   $((available_budget / 30000)) agents"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ============================================================================
# CLI Interface (when run directly)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, not sourced
    case "${1:-}" in
        current)
            get_current_tokens
            ;;
        available)
            get_available_budget
            ;;
        status)
            get_budget_status
            ;;
        report)
            print_budget_report
            ;;
        safe)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 safe <token-cost>"
                exit 1
            fi
            if is_spawn_safe "$2"; then
                echo "✓ Safe to spawn ($2 tokens)"
                exit 0
            else
                echo "✗ Not safe to spawn ($2 tokens)"
                exit 1
            fi
            ;;
        wait)
            if [ $# -lt 2 ]; then
                echo "Usage: $0 wait <token-cost>"
                exit 1
            fi
            wait_time=$(get_wait_time "$2")
            echo "$wait_time"
            ;;
        *)
            echo "Token Budget Utilities"
            echo ""
            echo "Usage:"
            echo "  $0 current          - Get current token usage"
            echo "  $0 available        - Get available token budget"
            echo "  $0 status           - Get budget status (one line)"
            echo "  $0 report           - Print detailed budget report"
            echo "  $0 safe <cost>      - Check if spawn is safe for cost"
            echo "  $0 wait <cost>      - Get recommended wait time (seconds)"
            echo ""
            echo "Or source this file to use functions in your script:"
            echo "  source $0"
            echo "  current_tokens=\$(get_current_tokens)"
            exit 1
            ;;
    esac
fi
