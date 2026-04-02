#!/usr/bin/env python3
"""
synthesize_brief.py - Takes all module data, calls Claude CLI to format the morning brief.
Usage: python3 synthesize_brief.py --data '<json>'
       echo '<json>' | python3 synthesize_brief.py
Output: formatted brief string (stdout)
"""

import sys
import json
import os
import subprocess
import argparse
import tempfile

CLAUDE_BIN = os.path.expanduser("~/.nvm/versions/node/v24.14.0/bin/claude")
CLAUDE_TOKEN = "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"

PROMPT_TEMPLATE = """You are formatting a morning brief for Théo, a robotics/AI engineer.

Data:
{json_data}

Format the brief EXACTLY like this template (use the actual data):

☀️ [Weekday], [Date]

━━━ TODAY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📅 Calendar
  • [time] — [event]   (or "No events today" if empty)

📬 Inbox: [N unread][, [N flagged] flagged]
  → [sender]: [subject]  (only list flagged items, skip if none)

━━━ FOCUS ━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Tasks
  1. [task — project]
  2. [task — project]
  3. [task — project]
  (or "Nothing queued in Mission Control" if empty)

📄 Jobs: [N active] applications · [N to_apply] to submit

━━━ INTEL ━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 AI/Robotics
  1. [title] — [source]
     [annotation: abstract summary + why relevant to robotics/ML engineer, 30 words max]
  2. ...
  (list up to 5 items; if none: "No new papers today (weekend/holiday)")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Rules:
- Be concise. No fluff. No extra commentary.
- For intel: summarize what the paper/post proposes in plain English + why relevant. 30 words MAX per item.
- Output ONLY the formatted brief. Nothing before or after it.
- Use the actual date from calendar data or today's date if unavailable.
- Show ALL calendar events for today.
- Show top 3-5 tasks from the tasks list.
- Jobs section: show active count and to_apply count from jobs data.
"""


def build_prompt(data: dict) -> str:
    json_str = json.dumps(data, indent=2, ensure_ascii=False)
    return PROMPT_TEMPLATE.format(json_data=json_str)


def call_claude(prompt: str) -> str:
    env = os.environ.copy()
    env["CLAUDE_CODE_OAUTH_TOKEN"] = CLAUDE_TOKEN

    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False, encoding='utf-8') as f:
        f.write(prompt)
        tmp_path = f.name

    try:
        result = subprocess.run(
            [CLAUDE_BIN, "--print", "-p", prompt],
            capture_output=True,
            text=True,
            env=env,
            timeout=60
        )
        if result.returncode != 0:
            raise RuntimeError(f"Claude CLI error: {result.stderr.strip()}")
        return result.stdout.strip()
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


def main():
    parser = argparse.ArgumentParser(description="Synthesize morning brief using Claude")
    parser.add_argument("--data", type=str, help="JSON data string")
    args = parser.parse_args()

    if args.data:
        raw = args.data
    else:
        raw = sys.stdin.read().strip()

    if not raw:
        print("[synthesize_brief] ERROR: No data provided", file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"[synthesize_brief] ERROR: Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)

    prompt = build_prompt(data)
    brief = call_claude(prompt)
    print(brief)


if __name__ == "__main__":
    main()
