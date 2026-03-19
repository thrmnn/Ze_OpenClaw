#!/bin/bash
# push-git-status.sh — Push local git status for all projects to Mission Control
#
# Runs locally and POSTs each project's git data to the MC API,
# which stores it in Convex. This replaces the broken server-side git access.

set -euo pipefail

MC_URL="${MC_URL:-https://mission-control-ruby-zeta.vercel.app}"

push_project() {
  local name="$1"
  local path="$2"
  local url="${3:-}"

  if [ ! -d "$path/.git" ]; then
    echo "  skip $name (no git repo at $path)"
    return
  fi

  LAST_MSG=$(git -C "$path" log -1 --format="%s" 2>/dev/null || echo "No commits")
  LAST_AGE=$(git -C "$path" log -1 --format="%ar" 2>/dev/null || echo "unknown")
  HASH=$(git -C "$path" log -1 --format="%h" 2>/dev/null || echo "")
  DIRTY=$(git -C "$path" status --porcelain 2>/dev/null | grep -q . && echo "true" || echo "false")
  BRANCH=$(git -C "$path" branch --show-current 2>/dev/null || echo "main")

  # Determine health score from commit age
  AGE_TEXT=$(git -C "$path" log -1 --format="%cr" 2>/dev/null || echo "99 days ago")
  if echo "$AGE_TEXT" | grep -qE "(second|minute|hour)"; then
    HEALTH="green"
  elif echo "$AGE_TEXT" | grep -qE "^[123] day"; then
    HEALTH="yellow"
  else
    HEALTH="red"
  fi

  # Build URL field for JSON
  if [ -n "$url" ] && [ "$url" != "null" ]; then
    URL_JSON="\"$url\""
  else
    URL_JSON="null"
  fi

  # Escape commit message for JSON (replace quotes and backslashes)
  LAST_MSG_ESCAPED=$(echo "$LAST_MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')

  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$MC_URL/api/projects-git" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$name\",
      \"lastCommitMessage\": \"$LAST_MSG_ESCAPED\",
      \"lastCommitAge\": \"$LAST_AGE\",
      \"commitHash\": \"$HASH\",
      \"isDirty\": $DIRTY,
      \"branch\": \"$BRANCH\",
      \"healthScore\": \"$HEALTH\",
      \"url\": $URL_JSON
    }")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "  ok $name ($LAST_AGE) [$HEALTH]"
  else
    echo "  FAIL $name (HTTP $HTTP_CODE)"
  fi
}

echo "Pushing git status to $MC_URL ..."
push_project "LAI Paper"          "/home/theo/lai_paper"                       "null"
push_project "Personal Website"   "/home/theo/projects/website"                "https://thrmnn.github.io"
push_project "AI Agency"          "/home/theo/projects/ai-agency/landing"      "https://landing-seven-olive-75.vercel.app"
push_project "Mission Control"    "/home/theo/clawd/mission-control"           "https://mission-control-ruby-zeta.vercel.app"
push_project "Job Pipeline"       "/home/theo/projects/job-pipeline"           "null"
echo "Done."
