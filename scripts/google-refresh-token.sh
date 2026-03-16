#!/bin/bash
# Refresh Google OAuth token
set -e

TOKENS_FILE="$HOME/clawd/credentials/google-tokens.json"

# Extract values
REFRESH_TOKEN=$(jq -r '.refresh_token' "$TOKENS_FILE")
CLIENT_ID=$(jq -r '.client_id' "$TOKENS_FILE")
CLIENT_SECRET=$(jq -r '.client_secret' "$TOKENS_FILE")

# Refresh the token
RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$CLIENT_ID" \
  -d "client_secret=$CLIENT_SECRET" \
  -d "refresh_token=$REFRESH_TOKEN" \
  -d "grant_type=refresh_token")

# Extract new access token
NEW_ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')
EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in')

if [ "$NEW_ACCESS_TOKEN" != "null" ]; then
  # Calculate expiry time
  EXPIRY=$(date -u -d "+${EXPIRES_IN} seconds" +"%Y-%m-%dT%H:%M:%SZ")
  
  # Update tokens file
  jq --arg token "$NEW_ACCESS_TOKEN" --arg expiry "$EXPIRY" \
    '.token = $token | .expiry = $expiry' \
    "$TOKENS_FILE" > "${TOKENS_FILE}.tmp"
  mv "${TOKENS_FILE}.tmp" "$TOKENS_FILE"
  
  echo "$NEW_ACCESS_TOKEN"
else
  echo "Error refreshing token" >&2
  echo "$RESPONSE" >&2
  exit 1
fi
