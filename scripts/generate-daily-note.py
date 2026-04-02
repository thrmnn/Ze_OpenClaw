#!/usr/bin/env python3
"""
Daily Note Generator — Zé's Morning Automation
Auto-generates today's Obsidian daily note with training, priorities, and log sections.

Usage:
    python3 scripts/generate-daily-note.py              # Create today's note
    python3 scripts/generate-daily-note.py --dry-run    # Print to stdout only
    python3 scripts/generate-daily-note.py --date 2026-03-20  # Specific date
"""

import argparse
import json
import re
import sys
import urllib.request
from datetime import datetime
from pathlib import Path

# ── Config ──────────────────────────────────────────────────────────────────

VAULT = Path("/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vaults/Ob_Perso_Vault")
DAILY_DIR = VAULT / "Daily"
PROGRAM_FILE = VAULT / "Areas/Health & Habits/Training/Current-Program.md"
BACKLOG_API = "https://mission-control-ruby-zeta.vercel.app/api/backlog"

# Training schedule: day_of_week (0=Mon) → (session_name, program_day_header)
TRAINING_SCHEDULE = {
    0: ("Upper Hypertrophy A", "Day 1 — Upper Hypertrophy A"),
    1: ("Lower Hypertrophy", "Day 2 — Lower Hypertrophy"),
    2: None,  # Rest or BJJ
    3: ("Upper Strength B", "Day 3 — Upper Strength B"),
    4: ("Lower Strength", "Day 4 — Lower Strength"),
    5: None,  # BJJ or rest
    6: None,  # Rest
}

# Rest day labels by day of week
REST_LABELS = {
    2: "Rest day or BJJ — recovery + mobility. High carb if BJJ, low carb if rest.",
    5: "BJJ or rest — recovery. High carb if BJJ, low carb if rest.",
    6: "Rest day — recovery + mobility. Low carb day.",
}


# ── Training Parser ─────────────────────────────────────────────────────────

def parse_training_session(day_of_week: int) -> str:
    """Parse Current-Program.md and return the training section for today."""
    schedule = TRAINING_SCHEDULE.get(day_of_week)

    if schedule is None:
        label = REST_LABELS.get(day_of_week, "Rest day — recovery + mobility. Low carb day.")
        return f"## 🏋️ Training — Rest Day\n{label}\n"

    session_name, day_header = schedule

    if not PROGRAM_FILE.exists():
        return f"## 🏋️ Training — {session_name}\n*⚠️ Could not read Current-Program.md*\n"

    program = PROGRAM_FILE.read_text(encoding="utf-8")

    # Find the section for this day
    pattern = rf"## {re.escape(day_header)}\s*\n"
    match = re.search(pattern, program)
    if not match:
        return f"## 🏋️ Training — {session_name}\n*⚠️ Could not find '{day_header}' in program*\n"

    # Extract everything until the next ## heading or end of file
    section_start = match.end()
    next_section = re.search(r"\n## ", program[section_start:])
    section_end = section_start + next_section.start() if next_section else len(program)
    section = program[section_start:section_end].strip()

    # Parse the exercise table
    exercises = []
    for line in section.split("\n"):
        line = line.strip()
        # Match table rows: | Exercise | Sets x Reps | Rest | Notes |
        if line.startswith("|") and not line.startswith("|--") and "Exercise" not in line:
            cols = [c.strip() for c in line.split("|")[1:-1]]
            if len(cols) >= 2 and cols[0]:
                exercise = cols[0]
                sets_reps = cols[1]
                exercises.append(f"- [ ] {exercise} {sets_reps}")

    output = f"## 🏋️ Training — {session_name}\n"
    if exercises:
        output += "\n".join(exercises) + "\n"
    else:
        output += "*No exercises parsed — check Current-Program.md*\n"

    output += "\n**Carb day:** High (training day)\n"
    return output


# ── Backlog Fetch ───────────────────────────────────────────────────────────

def fetch_top_priorities() -> str:
    """Fetch top 3 priority-5 pending items from MC backlog API."""
    try:
        req = urllib.request.Request(BACKLOG_API, headers={"User-Agent": "ze-daily-note/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))

        # Handle both direct array and {items: [...]} responses
        items = data if isinstance(data, list) else data.get("items", data.get("backlog", []))

        # Filter: priority 5, status pending
        top = [
            item for item in items
            if item.get("priority") == 5 and item.get("status") == "pending"
        ][:3]

        if not top:
            # Fallback: just get top 3 by priority descending
            sorted_items = sorted(
                [i for i in items if i.get("status") == "pending"],
                key=lambda x: x.get("priority", 0),
                reverse=True,
            )
            top = sorted_items[:3]

        if not top:
            return "## 🎯 Top 3 Today\n*No pending items found in backlog*\n"

        lines = ["## 🎯 Top 3 Today"]
        for item in top:
            title = item.get("title", item.get("name", "Untitled"))
            lines.append(f"- [ ] {title}")

        return "\n".join(lines) + "\n"

    except Exception as e:
        return f"## 🎯 Top 3 Today\n*⚠️ Could not fetch backlog: {e}*\n"


# ── Note Builder ────────────────────────────────────────────────────────────

def build_daily_note(target_date: datetime) -> str:
    """Build the full daily note markdown."""
    day_name = target_date.strftime("%A")
    month_name = target_date.strftime("%B")
    date_num = target_date.day
    year = target_date.year
    day_of_week = target_date.weekday()  # 0=Monday

    parts = []

    # Header
    parts.append(f"# 📅 {day_name}, {month_name} {date_num} {year}")
    parts.append(f"*Generated by Zé at 08:00 BRT*\n")

    # Training
    parts.append(parse_training_session(day_of_week))

    # Top 3 priorities
    parts.append(fetch_top_priorities())

    # Daily log
    parts.append("## 📝 Log")
    parts.append("*Add notes throughout the day*\n")

    # Meals
    parts.append("## 🍽️ Meals")
    parts.append("- [ ] M1 (pre-workout):")
    parts.append("- [ ] M2 (post-workout):")
    parts.append("- [ ] M3:")
    parts.append("- [ ] M4:\n")

    # Workout log
    parts.append("## 💪 Workout Log")
    parts.append("*Fill after training*")
    parts.append("| Exercise | Set 1 | Set 2 | Set 3 | Set 4 |")
    parts.append("|----------|-------|-------|-------|-------|")
    parts.append("\n")

    # Footer
    # Generate a contextual observation
    is_training = TRAINING_SCHEDULE.get(day_of_week) is not None
    if day_of_week == 4:  # Friday
        observation = "End of the week — finish strong and close open loops."
    elif day_of_week == 0:  # Monday
        observation = "Fresh week. Set the tone with a solid training session."
    elif is_training:
        observation = "Training day — fuel up and push the weights."
    else:
        observation = "Recovery day — stretch, hydrate, review the week so far."

    parts.append("---")
    parts.append(f"*Zé's note: {observation}*")

    return "\n".join(parts) + "\n"


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Zé's Daily Note Generator")
    parser.add_argument("--dry-run", action="store_true", help="Print to stdout without writing")
    parser.add_argument("--date", type=str, help="Target date (YYYY-MM-DD), defaults to today")
    args = parser.parse_args()

    if args.date:
        target_date = datetime.strptime(args.date, "%Y-%m-%d")
    else:
        target_date = datetime.now()

    date_str = target_date.strftime("%Y-%m-%d")
    note_path = DAILY_DIR / f"{date_str}.md"
    note_content = build_daily_note(target_date)

    if args.dry_run:
        print(note_content)
        return 0

    # Ensure directory exists
    DAILY_DIR.mkdir(parents=True, exist_ok=True)

    if note_path.exists():
        # Append instead of overwriting
        existing = note_path.read_text(encoding="utf-8")
        combined = existing.rstrip("\n") + "\n\n---\n\n## --- Auto-generated section ---\n\n" + note_content
        note_path.write_text(combined, encoding="utf-8")
        print(f"📝 Appended auto-generated section to existing note: Daily/{date_str}.md")
    else:
        note_path.write_text(note_content, encoding="utf-8")
        print(f"✅ Daily note created: Daily/{date_str}.md")

    return 0


if __name__ == "__main__":
    sys.exit(main())
