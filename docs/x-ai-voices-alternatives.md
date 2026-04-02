# X (Twitter) AI Voices Monitoring - Alternatives

## Problem
Nitter instances are unreliable (frequently down, rate-limited, or blocked). The current RSS-based approach doesn't work consistently.

## Alternatives

### Option 1: X API v2 (Recommended)
**Pros:**
- Official, reliable access
- Free tier: 1,500 posts/month (50/day)
- Real-time data

**Cons:**
- Requires X developer account
- API key setup needed

**Setup:**
1. Create developer account: https://developer.twitter.com
2. Create app and get Bearer token
3. Save to `credentials/x-api.env`:
   ```
   X_BEARER_TOKEN=your_token_here
   ```
4. Update fetch script to use X API

**Cost:** Free (within limits)

### Option 2: Manual Curation
**Pros:**
- No API needed
- Full control
- Can use web interface

**Cons:**
- Manual work
- Not automated

**Approach:**
- Daily: Check X feed manually
- Note interesting posts in `memory/x-highlights.md`
- Include in morning brief from notes

### Option 3: RSS to Email Bridge
**Pros:**
- Leverages existing email monitoring
- No custom scraping

**Cons:**
- Requires third-party service
- May have delays

**Services:**
- RSSHub (self-hosted)
- Kill the Newsletter
- Zapier/IFTTT

## Current Status

**Script:** `scripts/fetch-x-voices.py`
**Status:** ⚠️ Unreliable (Nitter issues)
**Voices tracked:** karpathy, nvidiarobotics, asimovinc, lerobothf

## Recommendation

For you (Théo):
1. **Short term:** Manual curation (5 min/day checking your X feed)
2. **Long term:** Get X API free tier when you have time

The manual approach is actually better for quality - you'll catch nuance and context that automated scraping misses.

## Quick Manual Workflow

```bash
# When you see interesting AI posts on X:
echo "## $(date +%Y-%m-%d)" >> memory/x-highlights.md
echo "- @username: [brief note about insight]" >> memory/x-highlights.md

# Morning brief reads from x-highlights.md
```

Simple, reliable, and you're likely checking X anyway. 😌
