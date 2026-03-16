# HEARTBEAT.md - Proactive Monitoring

## Rotation Schedule (Check 1-2 items per heartbeat)

### Claude Code Usage (1x daily: end of day 20-23)
- Run `ccusage monthly --json` for current month stats
- Calculate daily burn rate: totalCost / day_of_month
- Project end-of-month cost: daily_rate × days_in_month
- Alert if projected >$100/month (adjust threshold as needed)
- Brief summary: current spend + daily avg + projection

### Email Check (2x daily: morning 9-11, evening 18-20)
- Check for new emails in zeclawd@gmail.com
- Flag urgent messages (based on sender/subject)
- Summarize count only (don't list all)

### Trello NOW Cards (1x daily: afternoon 14-17)
- Run: `bash ~/clawd/scripts/trello-synthesis.sh`
- Flag overdue or blocked cards
- Alert if >15 cards in NOW (overwhelmed)
- Brief status summary

### Calendar Check (2x daily: morning 9-10, afternoon 16-17)
- Run: `bash ~/clawd/scripts/calendar-check.sh`
- Alert if event <1 hour away
- Show next 3 events

### Drive Updates (1x daily: afternoon 14-17)
- Check for newly shared documents
- List new files only (not all files)

### Memory Search + Mission Control (1x daily: afternoon 14-17)
**Use QMD to search memory for recent TODOs and context:**
```bash
bash ~/clawd/scripts/mc-memory-search.sh "pending tasks OR recent decisions" query
```

**What it does:**
1. Searches memory files using QMD (semantic + keyword hybrid)
2. Returns top 3 most relevant snippets
3. Logs search to Mission Control for tracking
4. Uses 75-90% fewer tokens vs loading full MEMORY.md

**When to run:**
- 1x daily during afternoon heartbeat
- Before spawning subagents (search for context first)
- When user asks about past decisions/tasks

**Quick commands:**
- `mc-memory-search.sh "recent tasks" query` - Hybrid search (best quality)
- `mc-memory-search.sh "pending work" vsearch` - Semantic only
- `mc-memory-search.sh "CERN application" search` - Keyword only

**Benefits:**
- 75-90% fewer tokens per memory query
- Search ALL memory files, not just MEMORY.md
- Semantic understanding (finds meaning, not just keywords)
- Activity tracked in Mission Control dashboard

---

## State Tracking
Last check times stored in: `memory/heartbeat-state.json`

Example:
```json
{
  "lastChecks": {
    "ccusage": 1738015200,
    "email": 1738008000,
    "trello": 1737950400,
    "drive": 1737964800
  }
}
```

---

## Response Rules

**When nothing needs attention:**
Reply: `HEARTBEAT_OK`

**When alerting:**
- Keep it brief (1-2 sentences)
- Only critical/actionable info
- Don't spam with routine updates

**Quiet hours:**
23:00-08:00 (Brazil time) - Only critical alerts

---

## Current Rotation

Cycle through checks to minimize token usage:
1. Email → Trello → Drive → ccusage → Email → ...

Check ccusage once daily (evening). All others as scheduled above.
