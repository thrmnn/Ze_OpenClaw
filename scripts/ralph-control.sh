#!/bin/bash
# ralph-control.sh - Control Ralph Loop (start/stop/status)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/ralph-config.sh"

PID_FILE="$HOME/clawd/memory/ralph-loop.pid"

start_ralph() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "❌ Ralph is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    echo "🚀 Starting Ralph Loop..."
    nohup bash "$SCRIPT_DIR/ralph-loop.sh" > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    
    sleep 2
    
    if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "✅ Ralph started successfully (PID: $(cat "$PID_FILE"))"
        echo "📊 Monitor: tail -f $RALPH_LOG_FILE"
        return 0
    else
        echo "❌ Failed to start Ralph - check logs"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_ralph() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo "❌ Ralph is not running"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "❌ Ralph PID file exists but process is dead"
        rm -f "$PID_FILE"
        return 1
    fi
    
    echo "🛑 Stopping Ralph (PID: $pid)..."
    kill "$pid"
    
    # Wait up to 10 seconds for graceful shutdown
    for i in {1..10}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$PID_FILE"
            echo "✅ Ralph stopped"
            return 0
        fi
        sleep 1
    done
    
    # Force kill if still running
    echo "⚠️  Force killing Ralph..."
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "✅ Ralph force stopped"
}

status_ralph() {
    echo "=== Ralph Loop Status ==="
    echo ""
    
    # Check if running
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Status: ✅ RUNNING (PID: $(cat "$PID_FILE"))"
    else
        echo "Status: ❌ STOPPED"
    fi
    
    echo ""
    
    # Show state
    if [[ -f "$RALPH_STATE_FILE" ]]; then
        echo "Loop Stats:"
        jq -r '"  Iterations: \(.loop_count)\n  Total Spawns: \(.total_spawns)\n  Last Run: \(.last_run // "never")"' "$RALPH_STATE_FILE"
    fi
    
    echo ""
    
    # Show active spawns
    if [[ -f "$RALPH_ACTIVE_SPAWNS" ]]; then
        local active_count=$(jq 'length' "$RALPH_ACTIVE_SPAWNS")
        echo "Active Spawns: $active_count"
        
        if [[ $active_count -gt 0 ]]; then
            jq -r '.[] | "  - \(.card_name) (started: \(.started_at))"' "$RALPH_ACTIVE_SPAWNS"
        fi
    fi
    
    echo ""
    
    # Show recent log
    if [[ -f "$RALPH_LOG_FILE" ]]; then
        echo "Recent Log (last 5 lines):"
        tail -n 5 "$RALPH_LOG_FILE" | sed 's/^/  /'
    fi
}

restart_ralph() {
    stop_ralph || true
    sleep 2
    start_ralph
}

logs_ralph() {
    if [[ ! -f "$RALPH_LOG_FILE" ]]; then
        echo "❌ No log file found"
        return 1
    fi
    
    tail -f "$RALPH_LOG_FILE"
}

case "${1:-}" in
    start)
        start_ralph
        ;;
    stop)
        stop_ralph
        ;;
    restart)
        restart_ralph
        ;;
    status)
        status_ralph
        ;;
    logs)
        logs_ralph
        ;;
    *)
        echo "Ralph Loop Control"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start Ralph Loop"
        echo "  stop    - Stop Ralph Loop"
        echo "  restart - Restart Ralph Loop"
        echo "  status  - Show Ralph status and stats"
        echo "  logs    - Tail Ralph logs (Ctrl+C to exit)"
        echo ""
        echo "Control Cards (create on Trello board):"
        echo "  'PAUSE RALPH' - Pause loop (don't spawn new agents)"
        echo "  'STOP RALPH'  - Stop loop completely"
        exit 1
        ;;
esac
