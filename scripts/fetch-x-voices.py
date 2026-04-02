#!/usr/bin/env python3
"""
Fetch X (Twitter) posts from AI voices using Nitter RSS
Falls back to sample voices if user list not provided
"""

import feedparser
import json
from datetime import datetime, timedelta
import sys
import socket

# Sample AI voices (will be replaced with user's list)
SAMPLE_VOICES = [
    "karpathy",      # Andrej Karpathy - AI/ML
    "ylecun",        # Yann LeCun - Deep Learning
    "goodfellow_ian" # Ian Goodfellow - GANs
]

VOICES_FILE = "/home/theo/clawd/data/ai-voices.json"
CACHE_FILE = "/home/theo/clawd/memory/x-cache/{date}.json"

def load_voices():
    """Load AI voices list (user-provided or sample)"""
    try:
        with open(VOICES_FILE) as f:
            data = json.load(f)
            return data.get('voices', SAMPLE_VOICES)
    except FileNotFoundError:
        return SAMPLE_VOICES

def fetch_posts(username, hours=24):
    """Fetch recent posts from Nitter RSS (tries multiple instances)"""
    # Multiple Nitter instances as fallback
    nitter_instances = [
        "nitter.poast.org",
        "nitter.privacydev.net", 
        "nitter.cz",
        "nitter.net"
    ]
    
    # Set socket timeout
    socket.setdefaulttimeout(10)
    
    for instance in nitter_instances:
        nitter_url = f"https://{instance}/{username}/rss"
        
        try:
            feed = feedparser.parse(nitter_url)
            
            if not feed.entries:
                continue  # Try next instance
                
            posts = []
            cutoff = datetime.now() - timedelta(hours=hours)
            
            for entry in feed.entries[:10]:  # Max 10 posts
                try:
                    pub_date = datetime(*entry.published_parsed[:6])
                    if pub_date < cutoff:
                        continue
                        
                    posts.append({
                        'text': entry.title,
                        'url': entry.link,
                        'date': pub_date.isoformat()
                    })
                except:
                    continue
            
            if posts:
                return posts  # Success!
                
        except Exception as e:
            print(f"  {instance} failed for @{username}: {e}", file=sys.stderr)
            continue
    
    print(f"  All instances failed for @{username}", file=sys.stderr)
    return []

def summarize_posts(all_posts):
    """Generate summary of key themes (simple version)"""
    if not all_posts:
        return "No recent AI updates from monitored voices."
    
    # Simple summary: list recent interesting posts
    summary = []
    for username, posts in all_posts.items():
        if posts:
            # Take first post as representative
            post = posts[0]
            summary.append(f"• @{username}: {post['text'][:100]}...")
    
    return "\n".join(summary[:5])  # Max 5 items

def main():
    voices = load_voices()
    date = datetime.now().strftime("%Y-%m-%d")
    
    all_posts = {}
    for username in voices:
        posts = fetch_posts(username, hours=24)
        if posts:
            all_posts[username] = posts
    
    # Save cache
    cache_file = CACHE_FILE.format(date=date)
    with open(cache_file, 'w') as f:
        json.dump({
            'date': date,
            'voices': all_posts,
            'summary': summarize_posts(all_posts)
        }, f, indent=2)
    
    # Print summary
    print(summarize_posts(all_posts))

if __name__ == '__main__':
    main()
