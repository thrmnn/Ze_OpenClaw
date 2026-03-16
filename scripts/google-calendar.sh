#!/bin/bash
# Google Calendar API wrapper
set -e

ACCESS_TOKEN=$(cd "$(dirname "$0")" && ./google-refresh-token.sh)

case "$1" in
  list)
    # List upcoming events
    MAX_RESULTS=${2:-10}
    curl -s "https://www.googleapis.com/calendar/v3/calendars/primary/events?maxResults=$MAX_RESULTS&orderBy=startTime&singleEvents=true&timeMin=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
    ;;
  create)
    # Create event from JSON stdin
    curl -s -X POST "https://www.googleapis.com/calendar/v3/calendars/primary/events" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d @- | jq .
    ;;
  get)
    EVENT_ID="$2"
    curl -s "https://www.googleapis.com/calendar/v3/calendars/primary/events/$EVENT_ID" \
      -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
    ;;
  *)
    echo "Usage: $0 {list|create|get <eventId>}" >&2
    exit 1
    ;;
esac
