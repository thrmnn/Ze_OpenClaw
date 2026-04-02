# X (Twitter) AI Voices Monitoring - Implementation Plan

## Goal
Track key AI thought leaders on X, summarize daily insights, integrate into morning brief.

---

## AI Voices List
*To be provided by Théo*

Example format:
- @username1 - Name (Focus: LLMs, Scaling)
- @username2 - Name (Focus: AGI, Safety)
- @username3 - Name (Focus: Applications, Startups)

---

## Implementation Options

### Option 1: X API v2 (Recommended)
**Pros:**
- Official API
- Reliable
- Good rate limits (Free tier: 1,500 posts/month)

**Cons:**
- Requires X developer account
- OAuth setup

**Cost:** Free tier available

### Option 2: Nitter (Alternative)
**Pros:**
- No API key needed
- RSS feeds available
- Privacy-friendly

**Cons:**
- Unofficial, may break
- Rate limiting issues
- Some instances unreliable

### Option 3: RSS Feeds
**Pros:**
- Simple
- No auth needed
- nitter.net/username/rss

**Cons:**
- Depends on Nitter availability
- Limited data

---

## Workflow

### Daily (Morning, 7:30 AM Brazil time)

1. **Fetch Posts** (last 24h from each voice)
2. **Filter & Extract:**
   - Main tweets (not replies)
   - Threads
   - High engagement posts
3. **Analyze:**
   - Common themes
   - Major announcements
   - Interesting insights
4. **Summarize:**
   - 3-5 key updates
   - Links to important threads
5. **Include in Morning Brief:**
   ```
   🤖 AI Updates (via X):
   - [Theme]: [Summary] (@username)
   - [Announcement]: [Detail] (@username)
   - [Insight]: [Key point] (@username)
   ```

---

## Storage

**Cache tweets:** `memory/x-cache/YYYY-MM-DD.json`

Structure:
```json
{
  "date": "2026-01-27",
  "voices": [
    {
      "username": "username",
      "posts": [
        {
          "id": "123",
          "text": "...",
          "url": "...",
          "engagement": 1500
        }
      ]
    }
  ],
  "summary": "Key themes: ...",
  "highlights": [...]
}
```

---

## Technical Setup

### Using X API (Recommended)

1. **Create X Developer Account:**
   - Go to: https://developer.twitter.com/
   - Apply for API access (Free tier)
   - Create app

2. **Get Credentials:**
   - API Key
   - API Secret
   - Bearer Token

3. **Install Library:**
   ```bash
   pip install tweepy
   ```

4. **Fetch Script:**
   ```python
   import tweepy
   
   client = tweepy.Client(bearer_token=BEARER_TOKEN)
   
   # Get user timeline
   tweets = client.get_users_tweets(
       id=user_id,
       max_results=10,
       start_time=yesterday
   )
   ```

### Using Nitter RSS (Fallback)

```bash
# Fetch RSS feed
curl "https://nitter.net/username/rss" | parse_rss
```

---

## Integration with Morning Brief

Add new section to morning brief:

```
☀️ Good morning Théo!

🤖 AI Field Updates (from X):
- [Update 1]
- [Update 2]
- [Update 3]

📰 Top News:
...

💭 Today's thought:
...

📋 Your tasks:
...
```

---

## Rate Limits & Costs

### X API Free Tier:
- 1,500 tweets/month (read)
- ~50 tweets/day
- For 10 voices: 5 tweets each = safe

### Upgrade if needed:
- Basic ($100/mo): 10k tweets/month
- Pro ($5k/mo): 1M tweets/month

**Recommendation:** Start with free tier, monitor usage

---

## Next Steps

1. ✅ Théo provides list of AI voices
2. Create X developer account (or use Nitter)
3. Set up credentials
4. Build fetch script
5. Test summarization
6. Integrate with morning brief cron
7. Monitor for 1 week, adjust

---

## Alternative: Manual Curated List

If API setup is too complex initially:
- Create curated list in `memory/ai-voices.md`
- Manual weekly review
- Summary in morning brief

Then automate later.

---

## Notes

- Keep summaries concise (3-5 bullets max)
- Focus on actionable insights, not noise
- Filter out drama/controversy unless highly relevant
- Link to original threads for deep dives
