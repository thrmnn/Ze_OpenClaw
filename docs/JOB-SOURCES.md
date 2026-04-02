# Job Sources Documentation

## Overview
Documentation of job sources for remote ML/Robotics Engineer positions, including API availability, rate limits, and scraping approaches.

---

## Major Job Boards

### 1. LinkedIn Jobs
**URL:** https://www.linkedin.com/jobs/  
**API:** LinkedIn Jobs API (requires OAuth, restricted access)  
**Rate Limits:** 100 requests/day for non-partner applications  
**Scraping Approach:** 
- Use search URL with filters: `https://www.linkedin.com/jobs/search/?keywords=machine%20learning&location=Remote&f_E=2,3`
- Parse HTML with BeautifulSoup
- Requires rotating user agents to avoid blocks
- Data available: Title, Company, Location, Description, Posted date

**Challenges:**
- Aggressive anti-scraping measures
- Requires login for full descriptions
- CAPTCHA on excessive requests

**Recommendation:** Scraping with rate limiting (max 50 searches/day)

---

### 2. Indeed
**URL:** https://www.indeed.com/  
**API:** Indeed Publisher API (deprecated in 2021)  
**Rate Limits:** N/A (no public API)  
**Scraping Approach:**
- Search URL: `https://www.indeed.com/jobs?q=machine+learning+remote&l=Remote&explvl=entry_level`
- BeautifulSoup or Scrapy
- Use job keys for deduplication
- Data available: Title, Company, Salary (sometimes), Location, Description, Posted date

**Challenges:**
- HTML structure changes frequently
- Rate limiting after ~100 requests/hour
- Some jobs require account to view full description

**Recommendation:** Scraping with caching and exponential backoff

---

### 3. Glassdoor
**URL:** https://www.glassdoor.com/Job/  
**API:** No public API  
**Rate Limits:** Strict rate limiting, CAPTCHA common  
**Scraping Approach:**
- Search URL: `https://www.glassdoor.com/Job/jobs.htm?sc.keyword=machine+learning&locT=N&locId=1&jobType=fulltime&fromAge=7&minSalary=0&includeNoSalaryJobs=true&radius=0&cityId=-1&minRating=0.0&industryId=-1&sgocId=-1&seniorityType=entrylevel`
- Requires Selenium (JavaScript-heavy)
- Must handle dynamic loading

**Challenges:**
- Very aggressive anti-scraping
- Requires headless browser
- Slow to scrape

**Recommendation:** Low priority, scrape only if other sources insufficient

---

### 4. ZipRecruiter
**URL:** https://www.ziprecruiter.com/  
**API:** No public API  
**Rate Limits:** Moderate anti-scraping  
**Scraping Approach:**
- Search URL: `https://www.ziprecruiter.com/jobs-search?search=machine+learning&location=Remote&days=7`
- BeautifulSoup sufficient
- Clean HTML structure

**Challenges:**
- Requires cookie handling
- Some jobs redirect to external sites

**Recommendation:** Good scraping target, clean data

---

## Startup & Niche Boards

### 5. Wellfound (formerly AngelList Talent)
**URL:** https://wellfound.com/jobs  
**API:** GraphQL API (requires authentication)  
**Rate Limits:** Unknown, likely restricted  
**Scraping Approach:**
- Search URL: `https://wellfound.com/role/r/machine-learning-engineer?experience=0-2&remote=true`
- React-based, requires Selenium or API approach
- GraphQL endpoint: `https://wellfound.com/graphql`

**Challenges:**
- GraphQL requires reverse engineering
- Authentication may be needed for full access

**Recommendation:** Use GraphQL API with authenticated requests

---

### 6. Y Combinator Jobs
**URL:** https://www.ycombinator.com/jobs  
**API:** No official API  
**Rate Limits:** Minimal anti-scraping  
**Scraping Approach:**
- Simple HTML structure
- Search URL: `https://www.ycombinator.com/companies/jobs?keyword=machine%20learning&remote=true`
- BeautifulSoup sufficient

**Challenges:**
- Limited filters
- Not many robotics roles

**Recommendation:** Easy to scrape, good for startup jobs

---

### 7. Startup Jobs
**URL:** https://startup.jobs/  
**API:** No public API  
**Rate Limits:** Moderate  
**Scraping Approach:**
- Search URL: `https://startup.jobs/machine-learning-jobs`
- Clean HTML structure
- RSS feed available: `https://startup.jobs/feed`

**Challenges:**
- Smaller volume
- Mixed job quality

**Recommendation:** Use RSS feed for efficiency

---

## AI/ML Specific Boards

### 8. AI Jobs Network
**URL:** https://aijobs.net/  
**API:** No public API  
**Rate Limits:** Minimal  
**Scraping Approach:**
- Search URL: `https://aijobs.net/find/remote/machine-learning-engineer`
- Simple structure, BeautifulSoup
- Email alerts available (could subscribe and parse)

**Challenges:**
- Lower volume
- Some spam listings

**Recommendation:** Scrape with spam filtering

---

### 9. MLjobs.ai
**URL:** Not found / may not exist  
**Status:** Need to verify existence  

---

### 10. Remote.co
**URL:** https://remote.co/remote-jobs/  
**API:** No public API  
**Rate Limits:** Minimal  
**Scraping Approach:**
- Category URL: `https://remote.co/remote-jobs/developer/`
- Simple HTML, BeautifulSoup
- Good remote-specific filtering

**Challenges:**
- Broad categories, need filtering
- Mixed quality

**Recommendation:** Good for verified remote roles

---

## Direct Channels

### 11. Reddit - r/MachineLearningJobs
**URL:** https://www.reddit.com/r/MachineLearningJobs/  
**API:** Reddit API (PRAW library)  
**Rate Limits:** 60 requests/minute  
**Scraping Approach:**
- Use PRAW (Python Reddit API Wrapper)
- Filter posts by flair: "Hiring", "Remote"
- Parse post content and comments

**Example:**
```python
import praw
reddit = praw.Reddit(client_id='...', client_secret='...', user_agent='...')
subreddit = reddit.subreddit('MachineLearningJobs')
for post in subreddit.new(limit=100):
    if 'remote' in post.title.lower():
        # Parse and validate
```

**Recommendation:** High quality, use Reddit API

---

### 12. Hacker News - Who's Hiring
**URL:** https://news.ycombinator.com/  
**API:** Hacker News API  
**Rate Limits:** None officially, be respectful  
**Scraping Approach:**
- Use HN Algolia API: `https://hn.algolia.com/api/v1/search?query=who%20is%20hiring&tags=story`
- Find monthly "Who is Hiring" threads
- Parse comments for job postings
- Filter by keywords: remote, ML, robotics

**Example:**
```python
import requests
r = requests.get('https://hn.algolia.com/api/v1/search?query=who%20is%20hiring&tags=story')
stories = r.json()['hits']
# Get latest monthly thread
latest = stories[0]
# Fetch comments
```

**Recommendation:** Excellent quality, monthly only

---

## Company Career Pages

### 13. Target Companies List
Direct career page monitoring for top robotics/ML companies:

**Robotics Companies:**
- Boston Dynamics: https://www.bostondynamics.com/careers
- Anduril: https://www.anduril.com/careers
- Skydio: https://www.skydio.com/careers
- Zipline: https://flyzipline.com/careers
- Waymo: https://waymo.com/careers
- Aurora: https://aurora.tech/careers

**ML/AI Companies:**
- Hugging Face: https://huggingface.co/jobs
- Weights & Biases: https://wandb.ai/careers
- Scale AI: https://scale.com/careers
- Anthropic: https://www.anthropic.com/careers
- OpenAI: https://openai.com/careers

**Scraping Approach:**
- Each has different structure (Greenhouse, Lever, Workday, custom)
- Use Selenium or Playwright for dynamic sites
- Check for "Remote" filter and entry-level roles

**Recommendation:** Target 20-30 companies, scrape weekly

---

## Summary & Recommendations

### Tier 1 (High Priority, Easy to Scrape)
1. Indeed - Large volume, stable structure
2. ZipRecruiter - Clean data
3. Y Combinator Jobs - Startup focus
4. Remote.co - Remote-specific
5. Hacker News API - High quality monthly

### Tier 2 (Good Quality, Moderate Effort)
6. Wellfound - Startup jobs, requires API work
7. Reddit API - Good community signal
8. Startup Jobs (RSS) - Easy integration
9. AI Jobs Network - Niche but relevant

### Tier 3 (Lower Priority)
10. LinkedIn - Anti-scraping issues, requires care
11. Glassdoor - Difficult to scrape, low ROI
12. Company pages - High effort, targeted approach

### Implementation Strategy

**Phase 1:** Implement Tier 1 sources (5 sources)
- Test with 100 jobs from each
- Build scrapers with retry logic
- Validate data quality

**Phase 2:** Add Tier 2 sources (4 sources)
- Implement API integrations (Reddit, HN)
- RSS parsing
- GraphQL for Wellfound

**Phase 3:** Add select company pages (10-15 companies)
- Focus on known robotics/ML leaders
- Weekly scraping schedule

**Total:** 15-20 sources for comprehensive coverage

---

## Technical Requirements

### Libraries
- **BeautifulSoup4** - HTML parsing
- **Scrapy** - Advanced scraping framework
- **Selenium/Playwright** - JavaScript-heavy sites
- **PRAW** - Reddit API
- **requests** - HTTP requests
- **cloudscraper** - Cloudflare bypass

### Best Practices
- Rotate user agents
- Respect robots.txt
- Implement exponential backoff
- Cache responses
- Log all requests
- Handle errors gracefully
- Monitor for structure changes

### Rate Limiting
- Max 1 request/second per source
- Daily limits: 500 requests total
- Track failed requests
- Implement circuit breaker pattern

---

**Created:** 2026-01-31  
**Status:** Research complete, ready for implementation  
**Next:** Design validation engine
