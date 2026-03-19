#!/bin/bash
# Setup X (Twitter) API v2 for AI voices monitoring
set -e

echo "=== X (Twitter) API v2 Setup ==="
echo
echo "Prerequisites:"
echo "1. X Developer account: https://developer.twitter.com"
echo "2. Create a project and app"
echo "3. Get Bearer Token from app settings"
echo
echo "Free tier limits:"
echo "  - 1,500 posts/month (50/day)"
echo "  - Perfect for monitoring AI voices"
echo

read -p "Do you have your Bearer Token ready? (y/n): " has_token

if [ "$has_token" != "y" ]; then
  echo
  echo "Steps to get your Bearer Token:"
  echo "1. Go to https://developer.twitter.com/en/portal/dashboard"
  echo "2. Create a project (if you don't have one)"
  echo "3. Create an app"
  echo "4. Go to Keys and Tokens"
  echo "5. Generate Bearer Token"
  echo
  echo "Run this script again when you have the token."
  exit 1
fi

read -p "Enter your X API Bearer Token: " bearer_token

# Save to credentials
mkdir -p ~/clawd/credentials
cat > ~/clawd/credentials/x-api.env << EOF
X_BEARER_TOKEN=$bearer_token
EOF

chmod 600 ~/clawd/credentials/x-api.env

echo
echo "✅ Credentials saved to ~/clawd/credentials/x-api.env"
echo

# Create the new X API fetch script
cat > ~/clawd/scripts/fetch-x-voices-api.py << 'EOFSCRIPT'
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
        raise FileNotFoundError("Missing credentials/x-api.env. Run setup-x-api.sh")
    
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
    
    for username in voices:
        user_id = get_user_id(username)
        if user_id:
            tweets = fetch_recent_tweets(user_id, hours=24)
            if tweets:
                all_posts[username] = tweets
    
    # Save cache
    cache_file = CACHE_DIR / f"{date}.json"
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
EOFSCRIPT

chmod +x ~/clawd/scripts/fetch-x-voices-api.py

echo "✅ Created fetch-x-voices-api.py"
echo

# Test the API
echo "Testing X API connection..."
python3 ~/clawd/scripts/fetch-x-voices-api.py

echo
echo "=== Setup Complete! ==="
echo
echo "Script: ~/clawd/scripts/fetch-x-voices-api.py"
echo "Usage: ./scripts/fetch-x-voices-api.py"
echo
echo "This will be integrated into your morning brief automatically."
echo
