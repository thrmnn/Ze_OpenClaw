#!/usr/bin/env python3
"""
Fetch X (Twitter) posts from AI voices using official X API v2
Requires X_BEARER_TOKEN in credentials/x-api.env
"""

import os
import json
import requests
from datetime import datetime, timedelta
from pathlib import Path

# Load credentials
def load_bearer_token():
    env_file = Path.home() / "clawd/credentials/x-api.env"
    if not env_file.exists():
        raise FileNotFoundError("Missing credentials/x-api.env")
    
    with open(env_file) as f:
        for line in f:
            if line.startswith("X_BEARER_TOKEN="):
                return line.split("=", 1)[1].strip()
    raise ValueError("X_BEARER_TOKEN not found in x-api.env")

BEARER_TOKEN = load_bearer_token()
VOICES_FILE = Path.home() / "clawd/data/ai-voices.json"
CACHE_DIR = Path.home() / "clawd/memory/x-cache"
CACHE_DIR.mkdir(parents=True, exist_ok=True)

def load_voices():
    """Load AI voices list"""
    try:
        with open(VOICES_FILE) as f:
            data = json.load(f)
            return data.get('voices', [])
    except FileNotFoundError:
        return ["karpathy", "nvidiarobotics", "asimovinc", "lerobothf"]

def get_user_id(username):
    """Get user ID from username"""
    url = f"https://api.twitter.com/2/users/by/username/{username}"
    headers = {"Authorization": f"Bearer {BEARER_TOKEN}"}
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()["data"]["id"]
    else:
        print(f"Error fetching user ID for @{username}: {response.status_code}")
        print(f"Response: {response.text}")
        return None

def fetch_recent_tweets(user_id, hours=24):
    """Fetch recent tweets from user"""
    url = f"https://api.twitter.com/2/users/{user_id}/tweets"
    headers = {"Authorization": f"Bearer {BEARER_TOKEN}"}
    
    # Calculate time window
    start_time = (datetime.utcnow() - timedelta(hours=hours)).isoformat() + "Z"
    
    params = {
        "max_results": 10,
        "start_time": start_time,
        "tweet.fields": "created_at,public_metrics",
        "exclude": "retweets,replies"
    }
    
    response = requests.get(url, headers=headers, params=params)
    
    if response.status_code == 200:
        data = response.json()
        return data.get("data", [])
    else:
        print(f"Error fetching tweets for user {user_id}: {response.status_code}")
        return []

def summarize_posts(all_posts):
    """Generate summary of key themes"""
    if not all_posts:
        return "No recent AI updates from monitored voices."
    
    summary = []
    for username, tweets in all_posts.items():
        if tweets:
            # Take most engaging tweet (by likes + retweets)
            top_tweet = max(tweets, key=lambda t: t.get("public_metrics", {}).get("like_count", 0))
            text = top_tweet["text"]
            # Truncate if too long
            if len(text) > 120:
                text = text[:117] + "..."
            summary.append(f"• @{username}: {text}")
    
    return "\n".join(summary[:5])  # Max 5 items

def main():
    voices = load_voices()
    date = datetime.now().strftime("%Y-%m-%d")
    
    all_posts = {}
    
    print(f"Fetching posts from {len(voices)} AI voices...")
    for username in voices:
        print(f"  - @{username}...", end=" ")
        user_id = get_user_id(username)
        if user_id:
            tweets = fetch_recent_tweets(user_id, hours=24)
            if tweets:
                all_posts[username] = tweets
                print(f"✓ {len(tweets)} tweets")
            else:
                print("(no recent tweets)")
        else:
            print("✗ failed")
    
    # Save cache
    cache_file = CACHE_DIR / f"{date}.json"
    with open(cache_file, 'w') as f:
        json.dump({
            'date': date,
            'voices': all_posts,
            'summary': summarize_posts(all_posts)
        }, f, indent=2)
    
    print(f"\n✅ Cache saved to {cache_file}")
    print("\n🤖 AI Field Updates:")
    print(summarize_posts(all_posts))

if __name__ == '__main__':
    main()
