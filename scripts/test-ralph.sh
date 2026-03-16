#!/bin/bash
# test-ralph.sh - Verify Ralph Loop installation

set -euo pipefail

echo "=== Ralph Loop Installation Test ==="
echo ""

# Check files exist
echo "✓ Checking files..."
files=(
    "$HOME/clawd/scripts/ralph-loop.sh"
    "$HOME/clawd/scripts/ralph-config.sh"
    "$HOME/clawd/scripts/ralph-control.sh"
    "$HOME/clawd/docs/RALPH-LOOP.md"
)

for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $(basename "$file")"
    else
        echo "  ❌ $(basename "$file") - MISSING"
        exit 1
    fi
done

echo ""

# Check executables
echo "✓ Checking permissions..."
for script in ralph-loop.sh ralph-config.sh ralph-control.sh; do
    if [[ -x "$HOME/clawd/scripts/$script" ]]; then
        echo "  ✅ $script is executable"
    else
        echo "  ❌ $script is not executable"
        exit 1
    fi
done

echo ""

# Check dependencies
echo "✓ Checking dependencies..."
deps=("jq" "curl")
for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
        echo "  ✅ $dep installed"
    else
        echo "  ❌ $dep not found"
        exit 1
    fi
done

echo ""

# Check Trello credentials
echo "✓ Checking Trello credentials..."
if [[ -f "$HOME/clawd/credentials/trello.env" ]]; then
    source "$HOME/clawd/credentials/trello.env"
    if [[ -n "${TRELLO_API_KEY:-}" && -n "${TRELLO_TOKEN:-}" ]]; then
        echo "  ✅ Trello credentials configured"
    else
        echo "  ❌ Trello credentials incomplete"
        exit 1
    fi
else
    echo "  ❌ trello.env not found"
    exit 1
fi

echo ""

# Test Trello API access
echo "✓ Testing Trello API access..."
if curl -sf "https://api.trello.com/1/boards/699dc91ad27a2301f3acc5f1/lists?key=${TRELLO_API_KEY}&token=${TRELLO_TOKEN}" > /dev/null; then
    echo "  ✅ Trello API accessible"
else
    echo "  ❌ Trello API request failed"
    exit 1
fi

echo ""

# Check smart-spawn dependency
echo "✓ Checking smart-spawn system..."
if [[ -f "$HOME/clawd/scripts/smart-spawn.sh" ]]; then
    echo "  ✅ smart-spawn.sh found"
else
    echo "  ❌ smart-spawn.sh not found (required dependency)"
    exit 1
fi

if [[ -f "$HOME/clawd/scripts/token-utils.sh" ]]; then
    echo "  ✅ token-utils.sh found"
else
    echo "  ❌ token-utils.sh not found (required dependency)"
    exit 1
fi

echo ""

# Test control script
echo "✓ Testing control script..."
if bash "$HOME/clawd/scripts/ralph-control.sh" status > /dev/null 2>&1; then
    echo "  ✅ ralph-control.sh works"
else
    echo "  ⚠️  ralph-control.sh returned error (expected if not running)"
fi

echo ""
echo "========================================="
echo "✅ ALL TESTS PASSED"
echo "========================================="
echo ""
echo "Ralph Loop is ready to start!"
echo ""
echo "Quick Start:"
echo "  bash ~/clawd/scripts/ralph-control.sh start"
echo ""
echo "Documentation:"
echo "  cat ~/clawd/docs/RALPH-LOOP.md"
echo ""
