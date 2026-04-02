#!/bin/bash
# ralph-config.sh - Ralph Loop Configuration
# Autonomous task orchestration settings

# Trello Configuration
export RALPH_BOARD_ID="699dc91ad27a2301f3acc5f1"
export RALPH_SPRINT_LIST="Current Sprint"
export RALPH_PROGRESS_LIST="In Progress"
export RALPH_DONE_LIST="Done"

# Agent Spawn Limits
export RALPH_MAX_CONCURRENT=3          # Max agents running at once
export RALPH_MIN_LOOP_DELAY=120        # Seconds between loop iterations (2 min)
export RALPH_TOKEN_SAFETY_MARGIN=10000 # Extra token buffer for safety

# Task Selection
export RALPH_PRIORITY_KEYWORDS="urgent|critical|blocker|deadline"
export RALPH_SKIP_KEYWORDS="waiting|blocked|paused"
export RALPH_AUTO_LABEL="🤖 Ralph"     # Label to tag auto-assigned cards

# Control Cards (create these on your board to control Ralph)
export RALPH_PAUSE_CARD="PAUSE RALPH"  # Card name to pause the loop
export RALPH_STOP_CARD="STOP RALPH"    # Card name to stop completely

# State Tracking
export RALPH_STATE_FILE="$HOME/clawd/memory/ralph-state.json"
export RALPH_ACTIVE_SPAWNS="$HOME/clawd/memory/ralph-spawns.json"

# Mission Control Integration
export RALPH_MC_ENABLED=true

# Logging
export RALPH_LOG_FILE="$HOME/clawd/logs/ralph-loop.log"
export RALPH_VERBOSE=false

# Create required directories
mkdir -p "$(dirname "$RALPH_STATE_FILE")"
mkdir -p "$(dirname "$RALPH_LOG_FILE")"
