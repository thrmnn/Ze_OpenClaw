#!/usr/bin/env python3
"""
fetch_intel.py — Morning Brief v2: Intelligence Module
Fetches RSS feeds + HuggingFace daily papers + X/Nitter posts,
scores by relevance, and annotates top items via Claude.

Usage:
    python3 fetch_intel.py          # returns JSON to stdout
    python3 fetch_intel.py --test   # same, with step timing to stderr
"""

import json
import os
import re
import sys
import time
import subprocess
import ssl
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

try:
    import feedparser
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "feedparser", "-q", "--break-system-packages"], check=True)
    import feedparser

# ── Paths ─────────────────────────────────────────────────────────────────────
BASE = Path(__file__).resolve().parent.parent.parent   # ~/clawd
DATA = BASE / "data"

RSS_SOURCES   = DATA / "rss-sources.json"
AI_VOICES     = DATA / "ai-voices.json"
INTEREST_FILE = DATA / "interest-profile.json"

CUTOFF_HOURS = 24

# Sources where items are papers and the annotation must summarise the abstract
PAPER_SOURCES = {"arXiv Robotics", "arXiv ML", "HuggingFace Papers"}

# Browser-like UA to avoid bot-blocks
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/122.0 Safari/537.36"

# SSL context (verify certs, but don't fail on minor issues)
SSL_CTX = ssl.create_default_context()


# ── Helpers ───────────────────────────────────────────────────────────────────

def log(msg, test_mode=False):
    if test_mode:
        print(f"  {msg}", file=sys.stderr)


def http_get(url, timeout=8):
    """Fetch URL with browser UA. Returns raw bytes or raises."""
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, context=SSL_CTX, timeout=timeout) as r:
        return r.read()


def parse_feed_bytes(raw_bytes):
    """Parse raw feed bytes with feedparser."""
    return feedparser.parse(raw_bytes)


def within_cutoff(entry, hours=CUTOFF_HOURS):
    """True if entry was published within the last N hours (or no date available)."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    for attr in ("published_parsed", "updated_parsed"):
        t = getattr(entry, attr, None)
        if t:
            try:
                dt = datetime(*t[:6], tzinfo=timezone.utc)
                return dt >= cutoff
            except Exception:
                pass
    return True   # no date → include


def within_cutoff_iso(iso_str, hours=CUTOFF_HOURS):
    """True if ISO 8601 timestamp is within the last N hours."""
    try:
        cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
        dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
        return dt >= cutoff
    except Exception:
        return True


def clean_html(text):
    """Strip HTML tags and collapse whitespace."""
    text = re.sub(r"<[^>]+>", " ", text or "")
    text = re.sub(r"\s+", " ", text).strip()
    return text


def best_body(entry, is_paper=False, max_len=600):
    """Extract best available text from a feed entry."""
    for attr in ("summary", "description", "content"):
        val = getattr(entry, attr, None)
        if isinstance(val, list):
            val = val[0].get("value", "") if val else ""
        if val:
            return clean_html(val)[:max_len]
    return ""


# ── Step 1a: RSS Feeds ────────────────────────────────────────────────────────

def fetch_rss(test=False):
    with open(RSS_SOURCES) as f:
        config = json.load(f)

    items = []
    fetched = 0

    for src in config["sources"]:
        name = src["name"]
        url  = src["url"]

        # HuggingFace Papers is handled separately via JSON API
        if name == "HuggingFace Papers":
            continue

        try:
            t0 = time.time()
            raw = http_get(url, timeout=8)
            feed = parse_feed_bytes(raw)
            elapsed = time.time() - t0

            if feed.bozo and not feed.entries:
                log(f"[RSS] {name}: parse error ({feed.bozo_exception}), skipping", test)
                continue

            is_paper = name in PAPER_SOURCES
            count = 0
            for entry in feed.entries:
                if not within_cutoff(entry):
                    continue
                body = best_body(entry, is_paper=is_paper,
                                 max_len=600 if is_paper else 300)
                items.append({
                    "title":      clean_html(entry.get("title", "(no title)"))[:200],
                    "source":     name,
                    "url":        entry.get("link", ""),
                    "body":       body,
                    "type":       "paper" if is_paper else "news",
                    "score":      0,
                    "annotation": "",
                })
                count += 1

            fetched += 1
            log(f"[RSS] {name}: {count} items in {elapsed:.1f}s", test)

        except Exception as e:
            log(f"[RSS] {name}: failed ({e}), skipping", test)

    return items, fetched


# ── Step 1b: HuggingFace Daily Papers (JSON API) ──────────────────────────────

def fetch_hf_papers(test=False):
    """Fetch HuggingFace daily papers via their JSON API."""
    url = "https://huggingface.co/api/daily_papers"
    items = []
    try:
        t0 = time.time()
        raw = http_get(url, timeout=10)
        data = json.loads(raw)
        count = 0
        for p in data:
            published = p.get("publishedAt", "")
            if not within_cutoff_iso(published):
                continue
            paper = p.get("paper", {})
            title = clean_html(p.get("title") or paper.get("title", "(no title)"))[:200]
            # Prefer ai_summary if available, else paper summary
            abstract = clean_html(
                paper.get("ai_summary") or paper.get("summary") or p.get("summary", "")
            )[:600]
            paper_id = paper.get("id", "")
            link = f"https://huggingface.co/papers/{paper_id}" if paper_id else "https://huggingface.co/papers"
            items.append({
                "title":      title,
                "source":     "HuggingFace Papers",
                "url":        link,
                "body":       abstract,
                "type":       "paper",
                "score":      0,
                "annotation": "",
            })
            count += 1
        log(f"[HF]  HuggingFace Papers: {count} items in {time.time()-t0:.1f}s", test)
    except Exception as e:
        log(f"[HF]  HuggingFace Papers: failed ({e}), skipping", test)
    return items


# ── Step 2: X/Nitter ──────────────────────────────────────────────────────────

NITTER_INSTANCES = [
    "nitter.poast.org",
    "nitter.privacydev.net",
    "nitter.cz",
]


def fetch_nitter_user(username, test=False):
    """Try each Nitter instance until one works. Returns (posts, success)."""
    for instance in NITTER_INSTANCES:
        url = f"https://{instance}/{username}/rss"
        try:
            raw = http_get(url, timeout=5)
            feed = parse_feed_bytes(raw)
            if feed.bozo and not feed.entries:
                continue
            posts = []
            for entry in feed.entries:
                if not within_cutoff(entry):
                    continue
                text = clean_html(entry.get("title", "") or entry.get("summary", ""))[:200]
                posts.append({
                    "title":      f"@{username}: {text}",
                    "source":     f"@{username}",
                    "url":        entry.get("link", f"https://x.com/{username}"),
                    "body":       text,
                    "type":       "post",
                    "score":      0,
                    "annotation": "",
                })
            return posts, True
        except Exception:
            continue
    return [], False


def fetch_x(test=False):
    with open(AI_VOICES) as f:
        config = json.load(f)

    all_voices = []
    for cat_voices in config["voices"].values():
        all_voices.extend(cat_voices)

    items = []
    x_available = False

    for username in all_voices:
        posts, ok = fetch_nitter_user(username, test)
        if ok:
            x_available = True
            items.extend(posts)
            log(f"[X]   @{username}: {len(posts)} posts", test)
        else:
            log(f"[X]   @{username}: all instances failed, skipping", test)

    return items, x_available


# ── Step 3: Score ─────────────────────────────────────────────────────────────

def build_keyword_sets(profile):
    """Tokenise interest profile phrases into matching terms (full phrases + words)."""
    def tokenise(phrases):
        tokens = set()
        for phrase in phrases:
            pl = phrase.lower()
            tokens.add(pl)
            tokens.update(pl.split())
        return tokens

    return {
        "core":       tokenise(profile["core"]),
        "secondary":  tokenise(profile["secondary"] + profile.get("companies", [])),
        "filter_out": tokenise(profile["filter_out"]),
    }


def score_item(item, kw):
    """Score 0–10 via keyword hits in title + body. No LLM."""
    haystack = (item["title"] + " " + item["body"]).lower()
    raw = 0

    for phrase in kw["filter_out"]:
        if phrase in haystack:
            raw -= 10

    for phrase in kw["core"]:
        if phrase in haystack:
            raw += 3

    for phrase in kw["secondary"]:
        if phrase in haystack:
            raw += 1

    raw = max(0, raw)
    return min(10.0, round(raw / 2, 1))


def score_all(items, test=False):
    with open(INTEREST_FILE) as f:
        profile = json.load(f)

    kw = build_keyword_sets(profile)

    for item in items:
        item["score"] = score_item(item, kw)

    items.sort(key=lambda x: x["score"], reverse=True)
    top = items[:10]
    top_score = top[0]["score"] if top else "n/a"
    log(f"[Score] Scored {len(items)} items, top score: {top_score}", test)
    return top


# ── Step 4: LLM Annotation ────────────────────────────────────────────────────

def _load_api_key():
    """Find the best available Anthropic API key from env or credential files."""
    # 1. Direct env var
    key = os.environ.get("ANTHROPIC_API_KEY", "")
    if key:
        return key

    # 2. Credential files under ~/clawd/credentials/
    cred_dir = BASE / "credentials"
    for fname in ("anthropic.env", "claude-code.env"):
        fpath = cred_dir / fname
        if fpath.exists():
            try:
                for line in fpath.read_text().splitlines():
                    line = line.strip().lstrip("export ")
                    if "ANTHROPIC_API_KEY=" in line:
                        val = line.split("=", 1)[1].strip().strip('"').strip("'")
                        if val:
                            return val
                    # Note: CLAUDE_CODE_OAUTH_TOKEN is not a valid x-api-key; skip it.
            except Exception:
                pass

    return ""


def call_claude(prompt):
    """Try anthropic library, then CLI. Returns text or None."""
    api_key = _load_api_key()
    if api_key:
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=api_key)
            msg = client.messages.create(
                model="claude-haiku-4-5",
                max_tokens=100,
                messages=[{"role": "user", "content": prompt}],
            )
            return msg.content[0].text.strip()
        except Exception:
            pass

    try:
        result = subprocess.run(
            ["claude", "--print", "-p", prompt],
            capture_output=True, text=True, timeout=20
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except Exception:
        pass

    return None


def build_annotation_prompt(item):
    """
    Papers (arXiv / HuggingFace):
        - Summarise what the paper does in plain English
        - Add why it's relevant to Théo (robotics/embodied-AI researcher)
        - Max 30 words total

    Posts / News:
        - Why it matters to Théo
        - Max 20 words
    """
    if item["type"] == "paper":
        return (
            f"Paper: {item['title']}\n"
            f"Abstract: {item['body'][:500]}\n\n"
            "Write ONE sentence (max 30 words) that: "
            "(1) summarises in plain English what this paper proposes or demonstrates, "
            "and (2) says why it's relevant to a robotics/embodied-AI researcher. "
            "Be direct. No 'This paper…' opener. No fluff."
        )
    else:
        return (
            f"Title: {item['title']}\n"
            f"Snippet: {item['body'][:200]}\n\n"
            "Write ONE phrase (max 20 words) explaining why this matters "
            "to a robotics/AI researcher focused on embodied AI, robot learning, "
            "and foundation models. Direct, no fluff."
        )


def annotate_top(items, test=False):
    """Annotate top 5 with LLM; fall back to body snippet on failure."""
    for i, item in enumerate(items[:5]):
        prompt = build_annotation_prompt(item)
        annotation = call_claude(prompt)
        if annotation:
            limit = 30 if item["type"] == "paper" else 20
            words = annotation.split()
            if len(words) > limit:
                annotation = " ".join(words[:limit]) + "…"
            item["annotation"] = annotation
            log(f"[LLM] Item {i+1} ({item['type']}): {annotation[:70]}…", test)
        else:
            fallback = item["body"][:120] if item["body"] else item["title"][:120]
            item["annotation"] = fallback
            log(f"[LLM] Item {i+1}: LLM unavailable, using snippet fallback", test)

    return items


# ── Main ──────────────────────────────────────────────────────────────────────

def run(test=False):
    total_start = time.time()

    # Step 1: RSS + HuggingFace
    log("\n── Step 1: Feeds ──", test)
    t0 = time.time()
    rss_items, feeds_fetched = fetch_rss(test)
    hf_items = fetch_hf_papers(test)
    all_feed_items = rss_items + hf_items
    feeds_fetched += (1 if hf_items else 0)
    log(f"[Feeds] Done: {len(all_feed_items)} items from {feeds_fetched} sources in {time.time()-t0:.1f}s", test)

    # Step 2: X/Nitter
    log("\n── Step 2: X/Nitter ──", test)
    t0 = time.time()
    x_items, x_available = fetch_x(test)
    log(f"[X] Done: {len(x_items)} posts in {time.time()-t0:.1f}s", test)

    all_items = all_feed_items + x_items
    total_candidates = len(all_items)

    # Step 3: Score
    log("\n── Step 3: Scoring ──", test)
    t0 = time.time()
    top_items = score_all(all_items, test)
    log(f"[Score] Done in {time.time()-t0:.2f}s", test)

    # Step 4: Annotate
    log("\n── Step 4: LLM Annotation ──", test)
    t0 = time.time()
    top_items = annotate_top(top_items, test)
    log(f"[LLM] Done in {time.time()-t0:.1f}s", test)

    log(f"\n── Total: {time.time()-total_start:.1f}s ──\n", test)

    output_items = [
        {
            "title":      item["title"],
            "source":     item["source"],
            "url":        item["url"],
            "score":      item["score"],
            "annotation": item["annotation"],
            "type":       item["type"],
        }
        for item in top_items
    ]

    return {
        "items":            output_items,
        "x_available":      x_available,
        "feeds_fetched":    feeds_fetched,
        "total_candidates": total_candidates,
    }


if __name__ == "__main__":
    test_mode = "--test" in sys.argv
    result = run(test=test_mode)
    print(json.dumps(result, indent=2, ensure_ascii=False))
