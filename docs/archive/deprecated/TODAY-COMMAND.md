# /today Command Documentation

## Purpose
Process daily notes into actionable task lists with context synthesis, without time-blocking or auto-prioritizing.

## Usage
```bash
bash ~/clawd/scripts/today-command.sh
```

Or simply tell Zé: `/today`

## What It Does

1. **Reads Daily Note** - Extracts raw notes from top of today's file
2. **Fetches Context** - Gets Trello NOW tasks for cross-reference
3. **Synthesizes** - Categorizes tasks by type:
   - ✅ Already Done
   - 🎯 Quick Wins (< 30min)
   - 🔬 Deep Focus (2-4h blocks)
   - 🚀 Active Projects (need scoping)
   - 🔧 System/Infrastructure
4. **Updates Daily Note** - Replaces raw notes with organized structure
5. **Syncs Trello** - Adds missing tasks to appropriate Trello lists
6. **Provides Recommendations** - Suggestions only, you prioritize

## Output Format

Short bullet list with:
- Task categorization
- Context from Trello
- Recommendations (not commands)
- Clear next actions

## Workflow

1. Add raw notes to top of daily note (before first `#` heading)
2. Run `/today` command
3. Review synthesized plan
4. Prioritize tasks yourself
5. Provide feedback to Zé for improvements

## Archives

- Previous daily notes processed and marked as complete
- Notes older than 7 days moved to Archive folder (manual trigger)
- Memory extraction requires manual approval before adding to MEMORY.md

## Created
2026-03-16 by Zé 😌
