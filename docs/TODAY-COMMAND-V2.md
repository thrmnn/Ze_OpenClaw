# /today Command - v2 Documentation

**Version:** 2.0  
**System:** Obsidian-first productivity with Trello execution dashboard

---

## Philosophy

**Obsidian = Source of Truth**  
Tasks originate from Obsidian (daily notes + project files)

**Trello = Execution Dashboard**  
Visual management for prioritization and workflow

---

## How It Works

### 1. Task Extraction

**Sources:**
- Today's daily note (`Daily/YYYY-MM-DD.md`)
- All project task files (`Projects/*/tasks.md`)
- Yesterday's unfinished tasks

**Format:** Tasks use `- [ ]` checkbox syntax

### 2. Next Action Detection

For each project with a `tasks.md` file:
- Find first incomplete task (`- [ ]`)
- Mark as project's Next Action
- Only one Next Action per project

### 3. Task Inventory

Combines:
- Today's daily note tasks
- Project Next Actions
- Yesterday's carryovers

### 4. Prioritization (Zé decides)

Zé analyzes and recommends based on:
1. Tasks with deadlines today
2. Tasks blocking other tasks
3. High-impact project tasks
4. Tasks started yesterday
5. Avoid multiple from same project

### 5. Trello Update

**Today list** (max 5):  
Top priorities for the day

**Next Actions list**:  
Remaining ready-to-work tasks

**Projects list**:  
Overview cards with links to Obsidian

---

## Usage

### Command Line
```bash
bash ~/clawd/scripts/today-command-v2.sh
```

### With Zé
Just say: `/today`

Zé will:
1. Run the script
2. Analyze task inventory
3. Recommend priorities
4. Update Trello
5. Update daily note

---

## Output

### Task Inventory Report
```
📊 Task Inventory:

From Today's Daily Note:
- [ ] Write homepage copy
- [ ] Review LAI paper

From Project Next Actions:
[PersonalWebsite] Design hero section
[LAI Paper] Implement Carlo's feedback
[Job Pipeline] Fix OAuth flow

From Yesterday (Unfinished):
- [ ] Organize X saved posts
```

### Trello Updates
- Cards created/moved to Today
- Next Actions refreshed
- Projects list updated

### Daily Note Update
- Organized task sections
- Priorities marked
- Context added

---

## Project Structure Required

For `/today` to work, projects must follow:

```
Projects/
  ProjectName/
    project.md    # Goals, roadmap
    notes.md      # Research, thinking
    tasks.md      # Actionable tasks ✓ REQUIRED
```

### tasks.md Format

```markdown
# ProjectName Tasks

## Next Actions
- [ ] First incomplete task becomes Next Action
- [ ] Second task

## Waiting
- [ ] Task blocked by X

## Completed
- [x] Done task
```

---

## Workflow Integration

### Morning Routine
1. Run `/today`
2. Review Trello Today list
3. Move top task to In Progress
4. Start work

### During Day
- Work from Trello Today/In Progress
- Update Obsidian as you complete
- Add new tasks to Obsidian (not Trello)

### Evening
- Mark completed in Obsidian tasks.md
- Update project notes
- Incomplete tasks carry to tomorrow

---

## Rules

### Obsidian
- ✅ Add tasks here first
- ✅ Keep tasks.md updated
- ✅ Use daily notes for capture
- ❌ Don't create tasks in Trello

### Trello
- ✅ Max 5 in Today
- ✅ Max 3 in In Progress
- ✅ One Next Action per project
- ❌ Don't add notes (use Obsidian)

### `/today` Command
- Run every morning (or on-demand)
- Updates are additive (doesn't delete manual tasks)
- Respects existing Today/In Progress limits
- Recommends, doesn't force prioritization

---

## Troubleshooting

**No tasks extracted?**
- Check daily note has `- [ ]` tasks
- Verify projects have tasks.md files
- Ensure checkbox format is correct

**Too many tasks in Today?**
- Zé will warn if >5 tasks
- Manual cleanup needed
- Follow prioritization rules

**Project not showing Next Action?**
- Check tasks.md exists
- Verify `- [ ]` format
- Ensure at least one incomplete task

---

## Related Commands

- `/review` - Weekly review and cleanup
- `/obsidian-sync` - Backup Obsidian vault
- `/trello-archive` - Archive Done cards

---

**Created:** 2026-03-16 by Zé 😌  
**System:** Productivity v2 (Obsidian-first)
