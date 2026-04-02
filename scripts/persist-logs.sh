#!/bin/bash
# Copy gateway logs from /tmp to persistent storage
SRC="/tmp/openclaw"
DST="$HOME/clawd/logs/openclaw"
mkdir -p "$DST"
# Copy recent logs (last 7 days)
find "$SRC" -name "*.log" -mtime -7 -exec cp -u {} "$DST/" \; 2>/dev/null
# Clean old persistent logs (>30 days)
find "$DST" -name "*.log" -mtime +30 -delete 2>/dev/null
