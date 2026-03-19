#!/usr/bin/env bash
# check-heartbeat-freshness.sh — Alert if any heartbeat check is >26h stale
set -euo pipefail

STATE_FILE="$HOME/clawd/memory/heartbeat-state.json"
THRESHOLD=93600  # 26 hours in seconds

if [[ ! -f "$STATE_FILE" ]]; then
  openclaw system event --text "⚠️ Heartbeat stale: state file missing at $STATE_FILE" --mode now
  exit 1
fi

NOW=$(date +%s)
STALE=""

while IFS='=' read -r key ts; do
  AGE=$(( NOW - ts ))
  if (( AGE > THRESHOLD )); then
    HOURS=$(( AGE / 3600 ))
    STALE="${STALE}${key} last ran ${HOURS}h ago; "
  fi
done < <(python3 -c "
import json, sys
with open('$STATE_FILE') as f:
    data = json.load(f)
for k, v in data.get('lastChecks', {}).items():
    print(f'{k}={v}')
")

if [[ -n "$STALE" ]]; then
  openclaw system event --text "⚠️ Heartbeat stale: ${STALE%%; }" --mode now
fi
