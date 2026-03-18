#!/usr/bin/env bash
# task-ledger.sh — CLI wrapper for Zé's persistent task ledger
# Uses Python3 stdlib for JSON manipulation

set -euo pipefail

LEDGER_FILE="$HOME/clawd/memory/active-tasks.json"

# Ensure ledger exists
if [ ! -f "$LEDGER_FILE" ]; then
    echo '{"tasks":[],"last_updated":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > "$LEDGER_FILE"
fi

usage() {
    echo "Usage:"
    echo "  task-ledger.sh add <label> <summary> [session_id]  — register new task"
    echo "  task-ledger.sh done <id> <result>                  — mark task done"
    echo "  task-ledger.sh fail <id> <error>                   — mark task failed"
    echo "  task-ledger.sh cancel <id>                         — mark task cancelled"
    echo "  task-ledger.sh status                              — show active tasks"
    echo "  task-ledger.sh clear                               — remove done/failed > 24h"
    echo "  task-ledger.sh get <id>                            — get single task JSON"
    exit 1
}

[ $# -lt 1 ] && usage

CMD="$1"
shift

case "$CMD" in
    add)
        [ $# -lt 2 ] && { echo "Error: add requires <label> <summary> [session_id]"; exit 1; }
        LABEL="$1"
        SUMMARY="$2"
        SESSION_ID="${3:-}"
        python3 -c "
import json, uuid, sys
from datetime import datetime, timezone
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

task_id = uuid.uuid4().hex[:8]
task = {
    'id': task_id,
    'label': '$LABEL',
    'status': 'running',
    'agent': 'claude',
    'session_id': '$SESSION_ID' if '$SESSION_ID' else None,
    'started_at': datetime.now(timezone.utc).isoformat(),
    'completed_at': None,
    'summary': '''$SUMMARY''',
    'result': None,
    'error': None
}
ledger['tasks'].append(task)
ledger['last_updated'] = datetime.now(timezone.utc).isoformat()
ledger_path.write_text(json.dumps(ledger, indent=2))
print(task_id)
"
        ;;
    done)
        [ $# -lt 2 ] && { echo "Error: done requires <id> <result>"; exit 1; }
        TASK_ID="$1"
        RESULT="$2"
        python3 -c "
import json, sys
from datetime import datetime, timezone
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

found = False
for t in ledger['tasks']:
    if t['id'] == '$TASK_ID':
        t['status'] = 'done'
        t['completed_at'] = datetime.now(timezone.utc).isoformat()
        t['result'] = '''$RESULT'''
        found = True
        break

if not found:
    print('Error: task $TASK_ID not found', file=sys.stderr)
    sys.exit(1)

ledger['last_updated'] = datetime.now(timezone.utc).isoformat()
ledger_path.write_text(json.dumps(ledger, indent=2))
print('OK')
"
        ;;
    fail)
        [ $# -lt 2 ] && { echo "Error: fail requires <id> <error>"; exit 1; }
        TASK_ID="$1"
        ERROR="$2"
        python3 -c "
import json, sys
from datetime import datetime, timezone
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

found = False
for t in ledger['tasks']:
    if t['id'] == '$TASK_ID':
        t['status'] = 'failed'
        t['completed_at'] = datetime.now(timezone.utc).isoformat()
        t['error'] = '''$ERROR'''
        found = True
        break

if not found:
    print('Error: task $TASK_ID not found', file=sys.stderr)
    sys.exit(1)

ledger['last_updated'] = datetime.now(timezone.utc).isoformat()
ledger_path.write_text(json.dumps(ledger, indent=2))
print('OK')
"
        ;;
    cancel)
        [ $# -lt 1 ] && { echo "Error: cancel requires <id>"; exit 1; }
        TASK_ID="$1"
        python3 -c "
import json, sys
from datetime import datetime, timezone
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

found = False
for t in ledger['tasks']:
    if t['id'] == '$TASK_ID':
        t['status'] = 'cancelled'
        t['completed_at'] = datetime.now(timezone.utc).isoformat()
        found = True
        break

if not found:
    print('Error: task $TASK_ID not found', file=sys.stderr)
    sys.exit(1)

ledger['last_updated'] = datetime.now(timezone.utc).isoformat()
ledger_path.write_text(json.dumps(ledger, indent=2))
print('OK')
"
        ;;
    status)
        python3 "$HOME/clawd/scripts/task-status.py"
        ;;
    get)
        [ $# -lt 1 ] && { echo "Error: get requires <id>"; exit 1; }
        TASK_ID="$1"
        python3 -c "
import json, sys
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

for t in ledger['tasks']:
    if t['id'] == '$TASK_ID':
        print(json.dumps(t, indent=2))
        sys.exit(0)

print('Error: task $TASK_ID not found', file=sys.stderr)
sys.exit(1)
"
        ;;
    clear)
        python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

ledger_path = Path('$LEDGER_FILE')
ledger = json.loads(ledger_path.read_text())

cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
kept = []
removed = 0

for t in ledger['tasks']:
    if t['status'] in ('done', 'failed', 'cancelled') and t.get('completed_at'):
        completed = datetime.fromisoformat(t['completed_at'])
        if completed.tzinfo is None:
            completed = completed.replace(tzinfo=timezone.utc)
        if completed < cutoff:
            removed += 1
            continue
    kept.append(t)

ledger['tasks'] = kept
ledger['last_updated'] = datetime.now(timezone.utc).isoformat()
ledger_path.write_text(json.dumps(ledger, indent=2))
print(f'Cleared {removed} old tasks, {len(kept)} remaining')
"
        ;;
    *)
        usage
        ;;
esac
