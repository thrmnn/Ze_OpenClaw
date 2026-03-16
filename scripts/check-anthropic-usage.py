#!/usr/bin/env python3
"""
Check Anthropic API usage and limits
Requires: pip install anthropic
"""

import os
from anthropic import Anthropic

# Load API key
with open('/home/theo/clawd/credentials/anthropic.env') as f:
    for line in f:
        if line.startswith('ANTHROPIC_API_KEY='):
            api_key = line.split('=', 1)[1].strip()
            break

client = Anthropic(api_key=api_key)

try:
    # Note: Usage API endpoint may differ
    # This is a placeholder - will need to check Anthropic docs
    print("📊 Anthropic Usage Check")
    print("=" * 50)
    print("\n⚠️  API doesn't expose usage limits directly")
    print("Need to check: console.anthropic.com/settings/usage")
    print("\nAPI Key configured: ✅")
    print(f"Key: {api_key[:10]}...{api_key[-4:]}")
    
except Exception as e:
    print(f"❌ Error: {e}")
