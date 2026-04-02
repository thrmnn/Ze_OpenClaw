#!/usr/bin/env python3
"""
morning-brief-v2.py - Morning brief orchestrator.
Runs all 5 data modules in parallel, synthesizes via Claude, sends to Telegram.

Usage:
  python3 morning-brief-v2.py --dry-run    # print to stdout, no Telegram
  python3 morning-brief-v2.py --send-now   # run full pipeline + send
  python3 morning-brief-v2.py              # same as --send-now
"""

import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed, TimeoutError
from datetime import datetime
from pathlib import Path
import pytz

# Paths
CLAWD_DIR = Path("/home/theo/clawd")
MODULES_DIR = CLAWD_DIR / "scripts" / "brief-modules"
BRIEFS_DIR = CLAWD_DIR / "memory" / "briefs"
SYNTHESIZE = MODULES_DIR / "synthesize_brief.py"
OPENCLAW_BIN = os.path.expanduser("~/.nvm/versions/node/v24.14.0/bin/openclaw")
TELEGRAM_ID = "8158798678"
TIMEZONE = pytz.timezone("America/Sao_Paulo")

MODULES = {
    "calendar": MODULES_DIR / "fetch_calendar.py",
    "email":    MODULES_DIR / "fetch_email.py",
    "jobs":     MODULES_DIR / "fetch_jobs.py",
    "tasks":    MODULES_DIR / "fetch_tasks.py",
    "intel":    MODULES_DIR / "fetch_intel.py",
}

MODULE_TIMEOUT = 30       # default timeout per module
MODULE_TIMEOUTS = {       # per-module overrides
    "intel": 90,
}


def run_module(name: str, path: Path) -> tuple[str, dict]:
    """Run a data module and return (name, data_dict)."""
    timeout = MODULE_TIMEOUTS.get(name, MODULE_TIMEOUT)
    try:
        result = subprocess.run(
            [sys.executable, str(path), "--test"],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=str(CLAWD_DIR)
        )
        if result.returncode != 0:
            print(f"[brief] WARN: {name} exited {result.returncode}: {result.stderr.strip()[:200]}", file=sys.stderr)
            return name, {}

        raw = result.stdout.strip()
        if not raw:
            print(f"[brief] WARN: {name} returned empty output", file=sys.stderr)
            return name, {}

        # Find JSON in output (modules may print logs before JSON)
        # Try to parse from the last line that looks like JSON, or the full output
        data = None
        lines = raw.splitlines()
        for line in reversed(lines):
            line = line.strip()
            if line.startswith("{") or line.startswith("["):
                try:
                    data = json.loads(line)
                    break
                except json.JSONDecodeError:
                    pass

        if data is None:
            # Try full output
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                # Try to extract JSON block
                import re
                match = re.search(r'\{.*\}', raw, re.DOTALL)
                if match:
                    try:
                        data = json.loads(match.group())
                    except json.JSONDecodeError:
                        pass

        if data is None:
            print(f"[brief] WARN: {name} output not parseable as JSON:\n{raw[:300]}", file=sys.stderr)
            return name, {}

        print(f"[brief] ✅ {name}: OK", file=sys.stderr)
        return name, data

    except subprocess.TimeoutExpired:
        print(f"[brief] WARN: {name} timed out after {MODULE_TIMEOUT}s", file=sys.stderr)
        return name, {}
    except Exception as e:
        print(f"[brief] WARN: {name} error: {e}", file=sys.stderr)
        return name, {}


def collect_data() -> dict:
    """Run all modules in parallel and collect results."""
    print("[brief] Running data modules in parallel...", file=sys.stderr)
    results = {}

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            executor.submit(run_module, name, path): name
            for name, path in MODULES.items()
        }
        max_timeout = max(MODULE_TIMEOUTS.values()) if MODULE_TIMEOUTS else MODULE_TIMEOUT
        for future in as_completed(futures, timeout=max_timeout + 10):
            name, data = future.result()
            results[name] = data

    return results


def synthesize(data: dict) -> str:
    """Call synthesize_brief.py with collected data."""
    print("[brief] Synthesizing brief with Claude...", file=sys.stderr)
    json_data = json.dumps(data, ensure_ascii=False)

    result = subprocess.run(
        [sys.executable, str(SYNTHESIZE), "--data", json_data],
        capture_output=True,
        text=True,
        timeout=90,
        cwd=str(CLAWD_DIR)
    )

    if result.returncode != 0:
        raise RuntimeError(f"synthesize_brief failed: {result.stderr.strip()}")

    brief = result.stdout.strip()
    if not brief:
        raise RuntimeError("synthesize_brief returned empty output")

    return brief


def send_telegram(brief: str):
    """Send brief to Telegram via OpenClaw."""
    print("[brief] Sending to Telegram...", file=sys.stderr)
    result = subprocess.run(
        [OPENCLAW_BIN, "message", "send", "--channel", "telegram", "--target", TELEGRAM_ID, "-m", brief],
        capture_output=True,
        text=True,
        timeout=30
    )
    if result.returncode != 0:
        raise RuntimeError(f"OpenClaw send failed: {result.stderr.strip()}")
    print("[brief] ✅ Sent to Telegram", file=sys.stderr)


def save_brief(brief: str):
    """Save brief to ~/clawd/memory/briefs/YYYY-MM-DD.md"""
    now = datetime.now(TIMEZONE)
    date_str = now.strftime("%Y-%m-%d")
    BRIEFS_DIR.mkdir(parents=True, exist_ok=True)
    path = BRIEFS_DIR / f"{date_str}.md"
    path.write_text(brief, encoding="utf-8")
    print(f"[brief] ✅ Saved to {path}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Morning Brief v2 Orchestrator")
    parser.add_argument("--dry-run", action="store_true", help="Print brief to stdout, don't send")
    parser.add_argument("--send-now", action="store_true", help="Run full pipeline + send immediately")
    args = parser.parse_args()

    # Source claude-code.env if available
    creds_file = CLAWD_DIR / "credentials" / "claude-code.env"
    if creds_file.exists():
        with open(creds_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    key, _, val = line.partition("=")
                    os.environ.setdefault(key.strip(), val.strip())

    try:
        # Step 1: Collect data from all modules
        data = collect_data()

        # Add today's date for Claude context
        now = datetime.now(TIMEZONE)
        data["_meta"] = {
            "date": now.strftime("%Y-%m-%d"),
            "weekday": now.strftime("%A"),
            "time": now.strftime("%H:%M"),
            "timezone": "America/Sao_Paulo"
        }

        # Step 2: Synthesize
        brief = synthesize(data)

        # Step 3: Save
        save_brief(brief)

        # Step 4: Output or send
        if args.dry_run:
            print("\n" + "="*50)
            print(brief)
            print("="*50)
            word_count = len(brief.split())
            print(f"\n[brief] Word count: {word_count}", file=sys.stderr)
        else:
            send_telegram(brief)

        print("[brief] ✅ Done.", file=sys.stderr)

    except Exception as e:
        print(f"[brief] ❌ FATAL: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
