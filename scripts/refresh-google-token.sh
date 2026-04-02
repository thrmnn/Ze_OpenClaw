#!/bin/bash
# Refresh Google OAuth access_token using the stored refresh_token.
# Run via cron every 30 minutes. If the refresh_token itself is revoked,
# logs an alert and exits non-zero so the user knows to re-auth.
set -euo pipefail

TOKENS_FILE="$HOME/clawd/credentials/google-tokens.json"
LOG_FILE="$HOME/clawd/logs/google-token-refresh.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*" >> "$LOG_FILE"; }

if [ ! -f "$TOKENS_FILE" ]; then
  log "ERROR: $TOKENS_FILE not found"
  exit 1
fi

REFRESH_TOKEN=$(jq -r '.refresh_token // empty' "$TOKENS_FILE")
CLIENT_ID=$(jq -r '.client_id // empty' "$TOKENS_FILE")
CLIENT_SECRET=$(jq -r '.client_secret // empty' "$TOKENS_FILE")

if [ -z "$REFRESH_TOKEN" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  log "ERROR: Missing refresh_token, client_id, or client_secret in $TOKENS_FILE"
  exit 1
fi

RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "refresh_token=$REFRESH_TOKEN" \
  -d "grant_type=refresh_token")

NEW_ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token // empty')
EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in // empty')

if [ -n "$NEW_ACCESS_TOKEN" ] && [ -n "$EXPIRES_IN" ]; then
  EXPIRY=$(date -u -d "+${EXPIRES_IN} seconds" +"%Y-%m-%dT%H:%M:%S.000000Z")

  jq --arg token "$NEW_ACCESS_TOKEN" --arg expiry "$EXPIRY" \
    '.token = $token | .expiry = $expiry' \
    "$TOKENS_FILE" > "${TOKENS_FILE}.tmp"
  mv "${TOKENS_FILE}.tmp" "$TOKENS_FILE"

  log "OK: token refreshed, expires $EXPIRY"
  # Print token on stdout for callers that need it
  echo "$NEW_ACCESS_TOKEN"
else
  ERROR=$(echo "$RESPONSE" | jq -r '.error // "unknown"')
  ERROR_DESC=$(echo "$RESPONSE" | jq -r '.error_description // "no description"')
  log "FAIL: $ERROR — $ERROR_DESC"

  if [ "$ERROR" = "invalid_grant" ]; then
    log "ALERT: refresh_token revoked. Run: ~/clawd/venv-google/bin/python3 ~/clawd/scripts/google-oauth-reauth.py"
  fi

  exit 1
fi
