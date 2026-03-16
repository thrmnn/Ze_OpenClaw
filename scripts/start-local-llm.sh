#!/bin/bash
# Start Local LLM Server for OpenClaw
# Qwen 2.5 14B on localhost:8000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/clawd/logs"
PYTHON_BIN="$HOME/clawd/venv-cuda/bin/python"
mkdir -p "$LOG_DIR"

echo "🚀 Starting Local LLM Server (Qwen 2.5 14B)..."

# Check if already running
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    echo "✅ Server already running at http://localhost:8000"
    exit 0
fi

# Ensure we run with the env that contains llama_cpp + FastAPI deps
if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "❌ Python env not found at $PYTHON_BIN"
    exit 1
fi

# Start server in background
nohup "$PYTHON_BIN" "$SCRIPT_DIR/local-llm-server.py" --model qwen2.5-14b > "$LOG_DIR/local-llm-server.log" 2>&1 &
SERVER_PID=$!

echo "Server starting (PID: $SERVER_PID)..."
echo "Waiting for model to load (~30 seconds)..."

# Wait for server to be ready
for i in {1..60}; do
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        echo "✅ Server ready at http://localhost:8000"
        echo "📊 Model: Qwen 2.5 14B (Q4_K_M)"
        echo "💾 RAM usage: ~14GB"
        echo "📝 Logs: $LOG_DIR/local-llm-server.log"
        exit 0
    fi
    sleep 1
done

echo "❌ Server failed to start. Check logs: $LOG_DIR/local-llm-server.log"
exit 1
