#!/bin/bash
# Start Local LLM Server - Qwen3.5 0.8B (lightweight, full GPU)
# Runs on localhost:8000 for OpenClaw integration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/clawd/logs"
PYTHON_BIN="$HOME/clawd/venv-qwen35/bin/python"
mkdir -p "$LOG_DIR"

echo "Starting Local LLM Server (Qwen3.5 0.8B)..."

# Check if already running
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    CURRENT=$(curl -s http://localhost:8000/ | python3 -c "import sys,json; print(json.load(sys.stdin).get('model','unknown'))" 2>/dev/null || echo "unknown")
    echo "Server already running at http://localhost:8000 (model: $CURRENT)"
    echo "To switch models: pkill -f local-llm-server && bash $0"
    exit 0
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "Python env not found at $PYTHON_BIN"
    exit 1
fi

nohup "$PYTHON_BIN" "$SCRIPT_DIR/local-llm-server-qwen35.py" \
    > "$LOG_DIR/local-llm-server-qwen35.log" 2>&1 &
SERVER_PID=$!

echo "Server starting (PID: $SERVER_PID)..."
echo "Waiting for model to load..."

for i in {1..30}; do
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        echo "Server ready at http://localhost:8000"
        echo "Model: Qwen3.5-0.8B (transformers, float16, full GPU)"
        echo "Logs: $LOG_DIR/local-llm-server-qwen35.log"
        exit 0
    fi
    sleep 1
done

echo "Server failed to start. Check logs: $LOG_DIR/local-llm-server-qwen35.log"
exit 1
