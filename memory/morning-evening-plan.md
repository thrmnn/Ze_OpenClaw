# Morning Brief & Evening Summary - Implementation Plan

## Morning Brief (8-9 AM, Brazil time)

### Components:
1. **Top News** - 2-3 relevant headlines (positive/tech/science focus)
2. **Positive Thought** - Quote or affirmation
3. **Today's Tasks** - From Trello NOW list

### Implementation:
- Cron job at 8:00 AM Brazil time
- News source: RSS feeds or news API (free tier)
- Quote: Random from curated list
- Trello: Query NOW cards

### Message format:
```
☀️ Good morning Théo!

📰 Top News:
- [headline 1]
- [headline 2]

💭 Today's thought:
"[quote]" - [author]

📋 Your tasks:
1. [Task from Trello]
2. [Task from Trello]

Have a productive day! 😌
```

---

## Evening Summary (20:00-21:00 Brazil time)

### Components:
1. **Reflection Questions** - 3-4 prompts about the day
2. **Summary** - Based on responses + activities
3. **Habit Tracking** - Update Google Sheet

### Questions:
- What went well today?
- What challenged you?
- What did you learn?
- Tomorrow's priority?

### Implementation:
- Cron job at 20:00 Brazil time
- Interactive prompts via Telegram
- Store responses in memory/daily-reflections/
- Update habit tracking sheet

### Habit Tracking Sheet Structure:
| Date | Morning Brief Sent | Evening Summary Done | Tasks Completed | Notes |
|------|-------------------|---------------------|-----------------|-------|
| 2026-01-27 | ✅ | ✅ | 3/5 | Good focus day |

---

## Technical Setup

### Cron Jobs:
```bash
# Morning brief - 8:00 AM Brazil time (UTC-3)
0 8 * * * clawdbot gateway wake --text "morning-brief" --mode now

# Evening summary - 20:00 Brazil time
0 20 * * * clawdbot gateway wake --text "evening-summary" --mode now
```

### News Sources (Free):
- NewsAPI.org (free tier: 100 req/day)
- RSS feeds (Hacker News, TechCrunch, etc.)
- Google News RSS

### Quote Sources:
- Local JSON file with curated quotes
- Or API: ZenQuotes, Quotable.io

### Storage:
- Daily reflections: `memory/reflections/YYYY-MM-DD.md`
- Habit sheet: Google Sheets (need Drive write scope)

---

## Next Steps

1. Set up news API (NewsAPI or RSS)
2. Create quote database
3. Configure cron jobs
4. Build habit tracking sheet template
5. Test morning brief
6. Test evening summary flow
7. Enable Drive write scope for sheet updates

---

## Notes

- Keep morning brief concise (~200 words)
- Evening questions: 4 max to avoid fatigue
- Habit sheet: Weekly review on Sundays?
