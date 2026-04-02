# Obsidian Second Brain & Co-Working Loop

**Status:** ✅ Ready to use  
**Vault:** `/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault`  
**Helper:** `~/clawd/scripts/obsidian.sh`

---

## What's Working ✅

1. **Create notes programmatically** - Zé can create notes in your vault
2. **Search notes** - By name and content
3. **Direct file access** - WSL-compatible, no API dependencies
4. **Folder organization** - Automatic folder creation (e.g., `Inbox/`, `Daily/`, etc.)

---

## Proposed Structure

```
Obsidian Vault/
├── Inbox/              # Quick captures, unsorted notes
├── Daily/              # Daily notes (YYYY-MM-DD.md)
├── Projects/           # Project-specific notes
├── Areas/              # Ongoing responsibilities
├── Resources/          # Reference material
├── Archive/            # Completed/inactive content
└── Templates/          # Note templates
```

**Philosophy:** PARA method (Projects, Areas, Resources, Archives)

---

## Co-Working Loop Integration

### 1. **Capture (Inbox)**
When you tell Zé something important:
```bash
bash ~/clawd/scripts/obsidian.sh create "Inbox/$(date +%Y%m%d-%H%M) - Topic" "# Quick Note\n\n..."
```

### 2. **Daily Notes**
Zé can maintain daily logs:
```bash
bash ~/clawd/scripts/obsidian.sh create "Daily/$(date +%Y-%m-%d)" "# $(date +%Y-%m-%d)\n\n## Tasks\n\n## Notes\n\n## Decisions"
```

### 3. **Project Notes**
Link project work from Trello/Memory to Obsidian:
```bash
bash ~/clawd/scripts/obsidian.sh create "Projects/CERN Application" "# CERN Application\n\n[[Daily/2026-03-14]]\n\nStatus: In Progress"
```

### 4. **Knowledge Graph**
Use `[[wikilinks]]` to connect ideas:
- `[[Projects/CERN Application]]`
- `[[Daily/2026-03-14]]`
- `[[Resources/CV Template]]`

---

## Automation Workflows

### Morning Brief Integration
Add to HEARTBEAT.md or morning routine:
```bash
# Create/update today's daily note
bash ~/clawd/scripts/obsidian.sh create "Daily/$(date +%Y-%m-%d)" "# $(date +%Y-%m-%d)

## Schedule
$(bash ~/clawd/scripts/calendar-check.sh)

## Tasks from Trello
$(bash ~/clawd/scripts/trello-synthesis.sh | head -10)

## Memory Context
$(qmd query 'recent tasks' -n 3)
"
```

### Capture from Telegram
When you message Zé:
- "Remember: [text]" → Creates note in Inbox
- "Add to [project]: [text]" → Appends to project note
- "Daily note" → Creates/shows today's note

### Search Integration
Zé can search your vault during conversations:
```bash
bash ~/clawd/scripts/obsidian.sh search-content "CERN"
```

---

## Example Usage

### Create Daily Note
```bash
bash ~/clawd/scripts/obsidian.sh create "Daily/2026-03-14" "# 2026-03-14

## Morning
- [ ] Check emails
- [ ] Review Trello NOW

## Afternoon
- [ ] Work on CERN application

## Evening
- [ ] Plan tomorrow

## Notes
- 

## Decisions
- 
"
```

### Capture Idea
```bash
bash ~/clawd/scripts/obsidian.sh create "Inbox/Job Search Strategy" "# Job Search Strategy

Ideas from conversation with Zé:
- Focus on CERN-type roles
- Leverage physics background
- Connect with research labs

Next: Move to [[Projects/Job Hunt]]
"
```

### Link Notes Together
```bash
bash ~/clawd/scripts/obsidian.sh append "Projects/CERN Application" "

## References
- [[Inbox/Job Search Strategy]]
- [[Daily/2026-03-14]]
- [[Resources/CV - Physics Research]]
"
```

---

## Integration with Existing Tools

### Memory Files (clawd/memory/)
- **Raw logs:** `~/clawd/memory/YYYY-MM-DD.md` (system context)
- **Obsidian:** User-facing notes, knowledge base
- **Separation:** Memory = machine context, Obsidian = human knowledge

### Trello
- Task execution → Trello
- Project planning & notes → Obsidian
- Link Trello cards in Obsidian: `[Card Name](trello-url)`

### QMD (Quick Markdown Search)
- QMD searches `~/clawd/memory/` for system context
- Obsidian searches vault for knowledge base
- Complementary tools, different purposes

---

## Next Steps to Activate

### 1. **Create Folder Structure**
```bash
for folder in Inbox Daily Projects Areas Resources Archive Templates; do
  mkdir -p "/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault/$folder"
done
```

### 2. **Create Daily Note Template**
```bash
bash ~/clawd/scripts/obsidian.sh create "Templates/Daily" "# {{date}}

## 🌅 Morning
- [ ] 

## 🌞 Afternoon
- [ ] 

## 🌙 Evening
- [ ] 

## 📝 Notes


## 💡 Decisions


## 🔗 Links
- [[Projects/]]
"
```

### 3. **Test Workflow**
```bash
# Create today's note
bash ~/clawd/scripts/obsidian.sh create "Daily/$(date +%Y-%m-%d)" "# $(date +%Y-%m-%d)

Morning check complete ✅
"

# Search it
bash ~/clawd/scripts/obsidian.sh search-content "Morning"
```

---

## Commands Cheat Sheet

```bash
# List all notes
bash ~/clawd/scripts/obsidian.sh list

# Search by name
bash ~/clawd/scripts/obsidian.sh search "keyword"

# Search content
bash ~/clawd/scripts/obsidian.sh search-content "text"

# Create note
bash ~/clawd/scripts/obsidian.sh create "Folder/Name" "# Content"

# Read note
bash ~/clawd/scripts/obsidian.sh read "Folder/Name"

# Append to note
bash ~/clawd/scripts/obsidian.sh append "Folder/Name" "More content"

# Show vault path
bash ~/clawd/scripts/obsidian.sh path
```

---

## Ready to Use? ✅

**Yes!** You can now:

1. ✅ Create notes from Telegram via Zé
2. ✅ Search your knowledge base during conversations
3. ✅ Link ideas across notes with [[wikilinks]]
4. ✅ Maintain daily logs automatically
5. ✅ Build a personal knowledge graph

**Try it:**
> "Zé, create a daily note for today"  
> "Zé, search my Obsidian vault for CERN"  
> "Zé, add this idea to my Inbox: [idea]"

---

**Created:** 2026-03-14 16:52 GMT-3  
**By:** Zé 😌
