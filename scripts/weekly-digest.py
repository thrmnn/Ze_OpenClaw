#!/usr/bin/env python3
"""
Weekly Digest — Zé's Sunday Email
Collects data from all systems and sends a single summary email.

Usage:
    python3 scripts/weekly-digest.py              # Send digest email
    python3 scripts/weekly-digest.py --dry-run     # Print to stdout only
"""

import argparse
import base64
import json
import os
import sqlite3
import subprocess
import sys
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from pathlib import Path

# ── Config ──────────────────────────────────────────────────────────────────

RECIPIENT = "thermann.ai@gmail.com"
FROM_EMAIL = "zeclawd@gmail.com"
TRACKER_DB = Path.home() / "projects/job-pipeline/tracker.db"
HEARTBEAT_FILE = Path.home() / "clawd/memory/heartbeat-state.json"
TRADING_BOT_DIR = Path.home() / "projects/trading-bot"

PROJECTS = [
    ("LAI Paper", Path.home() / "lai_paper"),
    ("Personal Website", Path.home() / "projects/website"),
    ("AI Agency Landing", Path.home() / "projects/ai-agency/landing"),
    ("Mission Control", Path.home() / "clawd/mission-control"),
    ("Job Pipeline", Path.home() / "projects/job-pipeline"),
]

# ── Helpers ─────────────────────────────────────────────────────────────────

def week_ago():
    return (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")


def git_last_commit(repo_path):
    """Return (date_str, message, days_since) for last commit, or None."""
    if not (repo_path / ".git").exists():
        return None
    try:
        result = subprocess.run(
            ["git", "-C", str(repo_path), "log", "-1", "--format=%aI|||%s"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None
        date_str, message = result.stdout.strip().split("|||", 1)
        commit_date = datetime.fromisoformat(date_str)
        days_since = (datetime.now(commit_date.tzinfo) - commit_date).days
        short_date = commit_date.strftime("%b %d")
        return short_date, message[:80], days_since
    except Exception:
        return None


# ── Section Builders ────────────────────────────────────────────────────────

def section_job_applications():
    """Section 1: Job Applications from tracker.db"""
    if not TRACKER_DB.exists():
        return "📋 <b>Job Applications</b>", "<p>tracker.db not found — pipeline not initialized.</p>"

    conn = sqlite3.connect(str(TRACKER_DB))
    conn.row_factory = sqlite3.Row
    c = conn.cursor()
    cutoff = week_ago()

    # Applications submitted this week
    c.execute(
        "SELECT company, role, status FROM applications WHERE applied_at >= ? ORDER BY applied_at DESC",
        (cutoff,)
    )
    new_apps = c.fetchall()

    # Status changes this week (last_updated)
    c.execute(
        "SELECT company, role, status FROM applications WHERE last_updated >= ? AND applied_at < ? ORDER BY last_updated DESC",
        (cutoff, cutoff)
    )
    status_changes = c.fetchall()

    # Top 3 pending by fit score
    c.execute(
        "SELECT company, role, fit_score FROM applications WHERE status IN ('to_apply','applied') AND fit_score IS NOT NULL ORDER BY fit_score DESC LIMIT 3"
    )
    top_pending = c.fetchall()

    # Pipeline totals
    c.execute("SELECT status, COUNT(*) FROM applications GROUP BY status")
    totals = {row[0]: row[1] for row in c.fetchall()}
    conn.close()

    applied = totals.get("applied", 0)
    in_progress = totals.get("interviewing", 0) + totals.get("in_progress", 0)
    responses = totals.get("rejected", 0) + totals.get("offered", 0) + totals.get("accepted", 0)
    to_apply = totals.get("to_apply", 0)

    html = ""

    # Separate actually applied vs queued
    applied_this_week = [a for a in new_apps if a['status'] not in ('to_apply',)]
    queued_this_week = [a for a in new_apps if a['status'] == 'to_apply']

    if applied_this_week:
        html += "<p><b>Submitted this week:</b></p><ul>"
        for a in applied_this_week:
            html += f"<li>{a['company']} — {a['role']} ({a['status']})</li>"
        html += "</ul>"

    if queued_this_week:
        html += f"<p><b>Added to queue this week:</b> {len(queued_this_week)}</p><ul>"
        for a in queued_this_week:
            html += f"<li>{a['company']} — {a['role']}</li>"
        html += "</ul>"

    if not new_apps:
        html += "<p>No new applications or queue additions this week.</p>"

    if status_changes:
        html += "<p><b>Status changes:</b></p><ul>"
        for a in status_changes:
            html += f"<li>{a['company']} — {a['role']} → <b>{a['status']}</b></li>"
        html += "</ul>"

    if top_pending:
        html += "<p><b>Top pending (by fit score):</b></p><ul>"
        for a in top_pending:
            score = a['fit_score'] or "—"
            html += f"<li>{a['company']} — {a['role']} (score: {score})</li>"
        html += "</ul>"

    html += f"<p><b>Pipeline:</b> {to_apply} queued, {applied} applied, {in_progress} in progress, {responses} responses</p>"

    return "📋 <b>Job Applications</b>", html


def section_position_radar():
    """Section 2: Position Radar — new job discoveries."""
    if not TRACKER_DB.exists():
        return "🔭 <b>Position Radar</b>", "<p>No discovery data available.</p>"

    conn = sqlite3.connect(str(TRACKER_DB))
    c = conn.cursor()
    cutoff = week_ago()

    # Jobs discovered this week
    c.execute("SELECT COUNT(*) FROM discovered_jobs WHERE first_seen >= ?", (cutoff,))
    count = c.fetchone()[0]

    # Top 5 new matches
    c.execute(
        "SELECT company, title, score FROM discovered_jobs WHERE first_seen >= ? ORDER BY score DESC LIMIT 5",
        (cutoff,)
    )
    top_matches = c.fetchall()

    # New companies (distinct companies seen this week but not before)
    c.execute(
        "SELECT DISTINCT company FROM discovered_jobs WHERE first_seen >= ? AND company NOT IN (SELECT DISTINCT company FROM discovered_jobs WHERE first_seen < ?)",
        (cutoff, cutoff)
    )
    new_companies = [row[0] for row in c.fetchall()]
    conn.close()

    html = f"<p>Jobs discovered this week: <b>{count}</b></p>"

    if top_matches:
        html += "<p><b>Top new matches:</b></p><ul>"
        for company, title, score in top_matches:
            s = score if score else "—"
            html += f"<li>{company} — {title} (score: {s})</li>"
        html += "</ul>"
    else:
        html += "<p>No new matches this week. Radar scans scheduled.</p>"

    if new_companies:
        html += f"<p><b>New companies on watchlist:</b> {', '.join(new_companies[:10])}</p>"

    return "🔭 <b>Position Radar</b>", html


def section_trading_signals():
    """Section 3: Trading Signals."""
    if not TRADING_BOT_DIR.exists():
        return "📈 <b>Trading Signals</b>", "<p>Trading bot not installed.</p>"

    journal_dir = TRADING_BOT_DIR / "journal"
    log_dir = TRADING_BOT_DIR / "logs"
    cutoff = datetime.now() - timedelta(days=7)

    signals = []
    best_signal = None

    # Check journal files (YYYY-MM-DD.json or .md pattern)
    for search_dir in [journal_dir, log_dir]:
        if not search_dir.exists():
            continue
        for f in sorted(search_dir.iterdir(), reverse=True):
            try:
                file_date = datetime.fromtimestamp(f.stat().st_mtime)
                if file_date < cutoff:
                    continue
                if f.suffix == ".json":
                    with open(f) as fh:
                        data = json.load(fh)
                    if isinstance(data, list):
                        signals.extend(data)
                    elif isinstance(data, dict):
                        signals.append(data)
                elif f.suffix in (".md", ".txt", ".log"):
                    signals.append({"file": f.name, "date": file_date.strftime("%b %d")})
            except Exception:
                continue

    if not signals:
        return "📈 <b>Trading Signals</b>", "<p>Bot activating — first scan tomorrow 8:30am BRT</p>"

    html = f"<p>Signals fired this week: <b>{len(signals)}</b></p>"

    # Try to find best setup by score
    scored = [s for s in signals if isinstance(s, dict) and "score" in s]
    if scored:
        best = max(scored, key=lambda x: x.get("score", 0))
        ticker = best.get("ticker", best.get("symbol", "?"))
        html += f"<p><b>Best setup:</b> {ticker} (score: {best['score']})</p>"

    return "📈 <b>Trading Signals</b>", html


def section_health_habits():
    """Section 4: Health & Habits."""
    html = ""

    # Check heartbeat for context
    if HEARTBEAT_FILE.exists():
        try:
            with open(HEARTBEAT_FILE) as f:
                hb = json.load(f)
            notes = hb.get("notes", "")
            if notes:
                html += f"<p><i>System note: {notes[:200]}</i></p>"
        except Exception:
            pass

    # Check Obsidian workout logs (common vault paths)
    obsidian_paths = [
        Path.home() / "obsidian",
        Path.home() / "Obsidian",
        Path.home() / "Documents/Obsidian",
        Path.home() / "vaults",
    ]
    workout_found = False
    for vault in obsidian_paths:
        if not vault.exists():
            continue
        # Search for workout/training files from this week
        try:
            result = subprocess.run(
                ["find", str(vault), "-name", "*.md", "-newer",
                 (datetime.now() - timedelta(days=7)).strftime("/tmp/.weekly-digest-marker"),
                 "-path", "*workout*", "-o", "-path", "*training*", "-o", "-path", "*health*"],
                capture_output=True, text=True, timeout=5
            )
            if result.stdout.strip():
                files = result.stdout.strip().split("\n")
                html += f"<p>Training sessions logged: <b>{len(files)}</b></p>"
                workout_found = True
                break
        except Exception:
            continue

    if not workout_found:
        html += "<p>Log workouts in Obsidian Health & Habits to track here.</p>"

    return "💪 <b>Health & Habits</b>", html


def section_project_status():
    """Section 5: Active Projects Status."""
    rows = []
    for name, path in PROJECTS:
        info = git_last_commit(path)
        if info:
            date, msg, days = info
            if days > 3:
                status = f'<span style="color:#ff4444;">⚠ {days}d stale</span>'
            elif days > 1:
                status = f'<span style="color:#ffaa00;">{days}d ago</span>'
            else:
                status = f'<span style="color:#44ff44;">today</span>' if days == 0 else f'<span style="color:#44ff44;">yesterday</span>'
            rows.append(f"<tr><td>{name}</td><td>{date}</td><td>{msg}</td><td>{status}</td></tr>")
        else:
            rows.append(f'<tr><td>{name}</td><td colspan="3"><i>No git repo or no commits</i></td></tr>')

    html = """<table style="width:100%;border-collapse:collapse;">
    <tr style="border-bottom:1px solid #444;"><th style="text-align:left;padding:4px;">Project</th><th style="text-align:left;padding:4px;">Last Commit</th><th style="text-align:left;padding:4px;">Message</th><th style="text-align:left;padding:4px;">Status</th></tr>
    """ + "\n".join(rows) + "</table>"

    return "🚀 <b>Active Projects</b>", html


def section_ze_weekly_read():
    """Section 6: Zé's Weekly Read — heuristic-based observations."""
    observations = []
    focus = None

    # Check project staleness
    stale_projects = []
    for name, path in PROJECTS:
        info = git_last_commit(path)
        if info and info[2] > 3:
            stale_projects.append((name, info[2]))

    if stale_projects:
        names = ", ".join(f"{n} ({d}d)" for n, d in stale_projects)
        observations.append(f"Projects going stale: {names}. Consider a quick commit or status update.")

    # Check job applications this week
    if TRACKER_DB.exists():
        conn = sqlite3.connect(str(TRACKER_DB))
        c = conn.cursor()
        c.execute("SELECT COUNT(*) FROM applications WHERE applied_at >= ?", (week_ago(),))
        app_count = c.fetchone()[0]
        c.execute("SELECT COUNT(*) FROM applications WHERE status = 'to_apply'")
        queue_count = c.fetchone()[0]
        c.execute("SELECT COUNT(*) FROM applications WHERE applied_at >= ? AND status != 'to_apply'", (week_ago(),))
        actually_applied = c.fetchone()[0]
        conn.close()

        if actually_applied == 0:
            observations.append(f"No applications actually submitted this week. {queue_count} jobs queued — time to fire off some apps.")
        else:
            observations.append(f"{actually_applied} application(s) submitted this week. Keep the pipeline flowing.")
    else:
        observations.append("Job pipeline not set up yet. Run the tracker setup when ready.")

    # Check trading bot
    if not TRADING_BOT_DIR.exists():
        observations.append("Trading bot not installed yet.")
    else:
        journal = TRADING_BOT_DIR / "journal"
        if not journal.exists() or not any(journal.iterdir()) if journal.exists() else True:
            observations.append("Trading bot needs activation — no signals logged yet.")

    # Pad to at least 3 observations
    defaults = [
        "Review your weekly energy: which tasks gave you momentum vs. drained you?",
        "Check calendar for next week — block focus time before it fills up.",
        "Sync with your accountability systems: are reminders landing?",
    ]
    while len(observations) < 3:
        observations.append(defaults[len(observations) % len(defaults)])

    # Recommended focus
    if stale_projects:
        most_stale = max(stale_projects, key=lambda x: x[1])
        focus = f"Revive <b>{most_stale[0]}</b> — it's been {most_stale[1]} days since last activity."
    elif TRACKER_DB.exists():
        conn = sqlite3.connect(str(TRACKER_DB))
        c = conn.cursor()
        c.execute("SELECT company, role FROM applications WHERE status = 'to_apply' AND fit_score IS NOT NULL ORDER BY fit_score DESC LIMIT 1")
        row = c.fetchone()
        conn.close()
        if row:
            focus = f"Submit application to <b>{row[0]} — {row[1]}</b> (highest fit score in queue)."
        else:
            focus = "Scan for new positions and queue up high-fit applications."
    else:
        focus = "Set up job pipeline tracker to start tracking applications."

    html = "<ul>"
    for obs in observations[:3]:
        html += f"<li>{obs}</li>"
    html += "</ul>"
    html += f"<p>🎯 <b>Recommended focus:</b> {focus}</p>"

    return "🧠 <b>Zé's Weekly Read</b>", html


# ── Email Assembly ──────────────────────────────────────────────────────────

def build_digest_html():
    """Build the full digest HTML email."""
    today = datetime.now().strftime("%B %d, %Y")
    week_start = (datetime.now() - timedelta(days=6)).strftime("%b %d")
    week_end = datetime.now().strftime("%b %d")

    sections = [
        section_job_applications(),
        section_position_radar(),
        section_trading_signals(),
        section_health_habits(),
        section_project_status(),
        section_ze_weekly_read(),
    ]

    section_html = ""
    for title, body in sections:
        section_html += f"""
        <div style="background:#1a1a2e;border-radius:8px;padding:16px 20px;margin-bottom:16px;">
            <h2 style="margin:0 0 12px 0;font-size:18px;color:#e0e0ff;">{title}</h2>
            <div style="color:#ccc;font-size:14px;line-height:1.6;">{body}</div>
        </div>
        """

    html = f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;background:#0d0d1a;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
<div style="max-width:640px;margin:0 auto;padding:24px;">

    <div style="text-align:center;padding:20px 0 24px 0;">
        <h1 style="margin:0;color:#fff;font-size:24px;">📬 Weekly Digest</h1>
        <p style="margin:6px 0 0 0;color:#888;font-size:14px;">Week of {week_start} – {week_end}, 2026</p>
        <p style="margin:2px 0 0 0;color:#666;font-size:12px;">Generated {today} by Zé</p>
    </div>

    {section_html}

    <div style="text-align:center;padding:20px 0;border-top:1px solid #222;">
        <p style="color:#555;font-size:12px;margin:0;">Zé — Théo's AI assistant · Powered by Claude</p>
    </div>
</div>
</body>
</html>"""

    return html


def send_html_email(to, subject, html_body):
    """Send HTML email via Gmail API."""
    sys.path.insert(0, str(Path(__file__).parent.parent))
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build

    token_file = Path.home() / "clawd/credentials/google-tokens.json"
    if not token_file.exists():
        raise FileNotFoundError(f"OAuth tokens not found at {token_file}")

    creds = Credentials.from_authorized_user_file(str(token_file))
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        with open(token_file, 'w') as f:
            f.write(creds.to_json())

    service = build('gmail', 'v1', credentials=creds)

    msg = MIMEMultipart('alternative')
    msg['To'] = to
    msg['From'] = FROM_EMAIL
    msg['Subject'] = subject
    msg.attach(MIMEText(html_body, 'html', 'utf-8'))

    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
    sent = service.users().messages().send(userId='me', body={'raw': raw}).execute()
    return sent


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Zé's Weekly Digest")
    parser.add_argument("--dry-run", action="store_true", help="Print digest to stdout without sending")
    args = parser.parse_args()

    html = build_digest_html()

    week_start = (datetime.now() - timedelta(days=6)).strftime("%b %d")
    subject = f"Weekly Digest — Week of {week_start}"

    if args.dry_run:
        # Print a readable plain-text version + raw HTML
        print("=" * 60)
        print(f"  SUBJECT: {subject}")
        print(f"  TO: {RECIPIENT}")
        print(f"  FROM: {FROM_EMAIL}")
        print("=" * 60)
        print()

        # Also render sections as plain text for readability
        sections = [
            section_job_applications(),
            section_position_radar(),
            section_trading_signals(),
            section_health_habits(),
            section_project_status(),
            section_ze_weekly_read(),
        ]
        for title, body in sections:
            # Strip HTML tags for console output
            import re
            clean_title = re.sub(r'<[^>]+>', '', title)
            clean_body = re.sub(r'<[^>]+>', '', body)
            clean_body = clean_body.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
            print(f"── {clean_title} {'─' * (50 - len(clean_title))}")
            print(clean_body.strip())
            print()

        print("=" * 60)
        print("[DRY RUN] Email not sent. HTML body length:", len(html), "chars")
        print("=" * 60)
        return 0

    # Send the email
    try:
        result = send_html_email(RECIPIENT, subject, html)
        print(f"✅ Weekly digest sent!")
        print(f"   Message ID: {result['id']}")
        print(f"   To: {RECIPIENT}")
        print(f"   Subject: {subject}")
        return 0
    except Exception as e:
        print(f"❌ Failed to send digest: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
