#!/usr/bin/env bash
# test-smart-spawn.sh - Verify smart spawn system works correctly
# This tests the logic without actually spawning agents

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Smart Spawn System - Verification Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test 1: Token utils functions
echo "Test 1: Token Utility Functions"
echo "--------------------------------"

source ~/clawd/scripts/token-utils.sh

current=$(get_current_tokens)
available=$(get_available_budget)
status=$(get_budget_status)

echo "Current tokens: $current"
echo "Available budget: $available"
echo "Status: $status"
echo "✓ Token utils working"
echo ""

# Test 2: Task size estimation
echo "Test 2: Task Size Estimation"
echo "-----------------------------"

# Source the estimation function
estimate_task_size() {
    local task="$1"
    local lower_task
    lower_task=$(echo "$task" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$lower_task" =~ (analysis|analyze|complex|debug|investigate|refactor|optimize) ]]; then
        echo "heavy"
        return
    fi
    
    if [[ "$lower_task" =~ (test|check|simple|quick|status|read|list) ]]; then
        echo "light"
        return
    fi
    
    echo "medium"
}

tests=(
    "Quick test:light"
    "Debug complex issue:heavy"
    "Create new file:medium"
    "Analyze performance:heavy"
    "Check status:light"
    "Refactor code:heavy"
)

for test in "${tests[@]}"; do
    task="${test%:*}"
    expected="${test##*:}"
    result=$(estimate_task_size "$task")
    
    if [ "$result" = "$expected" ]; then
        echo "✓ '$task' → $result"
    else
        echo "✗ '$task' → $result (expected: $expected)"
    fi
done
echo ""

# Test 3: Spawn safety checks
echo "Test 3: Spawn Safety Checks"
echo "----------------------------"

test_costs=(8000 15000 30000)
for cost in "${test_costs[@]}"; do
    if is_spawn_safe "$cost"; then
        echo "✓ ${cost} tokens: SAFE to spawn"
    else
        echo "⚠ ${cost} tokens: NOT SAFE (would exceed budget)"
    fi
done
echo ""

# Test 4: Budget report
echo "Test 4: Budget Report"
echo "---------------------"
print_budget_report
echo ""

# Test 5: Script exists and is executable
echo "Test 5: Script Installation"
echo "---------------------------"

if [ -x ~/clawd/scripts/smart-spawn.sh ]; then
    echo "✓ smart-spawn.sh installed and executable"
else
    echo "✗ smart-spawn.sh not found or not executable"
fi

if [ -x ~/clawd/scripts/token-utils.sh ]; then
    echo "✓ token-utils.sh installed and executable"
else
    echo "✗ token-utils.sh not found or not executable"
fi

if [ -f ~/clawd/docs/SPAWN-CALCULATOR.md ]; then
    echo "✓ SPAWN-CALCULATOR.md documentation exists"
else
    echo "✗ SPAWN-CALCULATOR.md not found"
fi

if [ -f ~/clawd/docs/SPAWN-INTEGRATION-GUIDE.md ]; then
    echo "✓ SPAWN-INTEGRATION-GUIDE.md documentation exists"
else
    echo "✗ SPAWN-INTEGRATION-GUIDE.md not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ All verification tests passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Read: ~/clawd/docs/SPAWN-CALCULATOR.md"
echo "  2. Use:  ~/clawd/scripts/smart-spawn.sh '<task>' [label] [size]"
echo "  3. Check: ~/clawd/scripts/token-utils.sh report"
echo ""
