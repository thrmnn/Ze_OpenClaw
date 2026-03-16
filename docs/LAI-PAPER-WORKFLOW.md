# LAI Paper Automated Workflow - Complete System

**Date:** 2026-03-14  
**Status:** Ready for configuration  
**Purpose:** Streamline paper revisions with automated feedback → implementation → distribution

---

## 🎯 System Overview

### **What It Does**

Automates the complete revision cycle for your LAI paper:

1. **Feedback Collection** (Telegram or Obsidian)
2. **Change Proposal** (Zé analyzes and suggests edits)
3. **Implementation** (Zé edits LaTeX source)
4. **Compilation** (Automatic PDF generation)
5. **Distribution** (Email PDF to recipients)

### **Time Savings**

**Before:**
- Receive feedback → manually edit LaTeX → compile → check for errors → email PDF → repeat
- **Time:** 20-30 minutes per revision cycle

**After:**
- Send feedback to Zé → approve changes → done
- **Time:** 2-5 minutes (mostly approval)

---

## 📁 Files Created

### **In Obsidian Vault**

| File | Purpose |
|------|---------|
| `Projects/Academic Research/LAI Paper/Index.md` | Project hub with links |
| `Projects/Academic Research/LAI Paper/Feedback Log.md` | Revision tracking |
| `Projects/Academic Research/LAI Paper/Workflow Setup.md` | Complete setup guide |
| `Projects/Academic Research/LAI Paper/Quick Reference.md` | Fast command reference |

### **Scripts**

| Script | Location | Purpose |
|--------|----------|---------|
| `lai-paper-workflow.sh` | `~/clawd/scripts/` | Main automation engine |
| `send-email-with-attachment.py` | `~/clawd/scripts/` | Gmail API email sender |

---

## 🔄 Workflow Modes

### **Mode 1: Telegram Feedback (Fastest)**

**You:**
```
LAI paper: Revise introduction - clarify research gap
```

**Zé:**
1. Logs feedback to Obsidian Feedback Log
2. Reads LaTeX source
3. Proposes specific changes (e.g., "Add 2 sentences after line 34...")
4. Creates revision note with diff

**You:**
```
Apply changes
```

**Zé:**
1. Edits `lai_paper.tex`
2. Creates backup: `lai_paper.tex.backup.20260314-143000`
3. Compiles PDF with `pdflatex`
4. Emails PDF to configured recipient(s)
5. Updates Feedback Log with completion status

**Total time:** 2-3 minutes (most of it is your approval)

---

### **Mode 2: Obsidian Feedback (Detailed)**

**You:**
1. Open `Projects/Academic Research/LAI Paper/Feedback Log.md`
2. Add detailed feedback:
   ```markdown
   ### Active Feedback
   - Introduction: Strengthen problem statement
   - Methodology: Add diagram showing data flow
   - Results: Include Table 2 comparing approaches
   ```
3. Tell Zé: "Process LAI feedback"

**Zé:**
1. Reads all 3 feedback items
2. Proposes changes for each
3. Creates comprehensive revision note
4. Waits for approval

**You:**
- Review proposals in Obsidian
- Edit if needed
- Approve: "Apply LAI changes"

**Zé:**
- Implements all changes
- Compiles → Emails

**Total time:** 5-10 minutes (detailed review)

---

### **Mode 3: Manual Commands**

**Direct script execution:**
```bash
# Log feedback
bash ~/clawd/scripts/lai-paper-workflow.sh feedback "Your feedback text"

# Compile only
bash ~/clawd/scripts/lai-paper-workflow.sh compile

# Email only
bash ~/clawd/scripts/lai-paper-workflow.sh email supervisor@uni.edu

# Full workflow: compile + email
bash ~/clawd/scripts/lai-paper-workflow.sh publish supervisor@uni.edu

# Check status
bash ~/clawd/scripts/lai-paper-workflow.sh status
```

---

## 🛠️ Setup Required

### **Prerequisites**

- [x] LaTeX installed (`pdflatex` command available)
- [x] Gmail API configured (for email)
- [ ] LAI paper .tex file location configured
- [ ] Paths updated in `lai-paper-workflow.sh`
- [ ] Test compilation successful
- [ ] Test email successful

### **Step 1: Locate Your Paper**

**Find your LAI paper LaTeX files:**
```bash
# Search for .tex files
find /mnt/c/Users/theoh -name "*LAI*" -o -name "*lai*" 2>/dev/null | grep -i "\.tex$"

# Or manually browse to paper folder
```

**Example locations:**
- `/mnt/c/Users/theoh/Documents/LAI_Paper/`
- `/mnt/c/Users/theoh/OneDrive/Research/LAI/`
- `/mnt/c/Users/theoh/University/Papers/LAI/`

**Note:** Full path including `.tex` filename

---

### **Step 2: Configure Script**

**Edit:** `~/clawd/scripts/lai-paper-workflow.sh`

**Find lines 7-10:**
```bash
PAPER_DIR="/mnt/c/Users/theoh/OneDrive/Documents/LAI_Paper"
PAPER_TEX="$PAPER_DIR/lai_paper.tex"
```

**Update with your actual paths:**
```bash
PAPER_DIR="/mnt/c/Users/theoh/[YOUR_PATH]"
PAPER_TEX="$PAPER_DIR/[YOUR_FILE].tex"
```

**Via Zé:**
> "Update LAI paper path to /mnt/c/Users/theoh/Documents/MyPaper/paper.tex"

---

### **Step 3: Test Compilation**

```bash
# Check paths are correct
bash ~/clawd/scripts/lai-paper-workflow.sh status

# Try compiling
bash ~/clawd/scripts/lai-paper-workflow.sh compile
```

**Expected output:**
```
🔨 Compiling LaTeX to PDF...
This is pdfTeX, Version 3.14159265-2.6-1.40.20...
...
Output written on lai_paper.pdf (X pages, Y bytes).
✅ PDF compiled successfully: /path/to/lai_paper.pdf
```

**If errors:**
- Check LaTeX syntax in your .tex file
- Install missing packages: `sudo apt install texlive-latex-extra`
- Verify file permissions

---

### **Step 4: Test Email**

```bash
bash ~/clawd/scripts/lai-paper-workflow.sh email your.email@example.com "Test"
```

**Expected:**
- Email arrives with PDF attached
- Subject: "Test"
- Body: Auto-generated message

**If fails:**
- Verify Gmail credentials: `~/clawd/credentials/google-tokens.json`
- Test email script: `python3 ~/clawd/scripts/send-email-with-attachment.py --help`
- Re-authenticate if needed: `openclaw configure --section model`

---

## 💡 Example Use Cases

### **Use Case 1: Supervisor Revision Request**

**Supervisor emails:**
> "Please expand the literature review section. Add more recent papers (2024-2025)."

**You (Telegram to Zé):**
> "LAI paper: Expand literature review with recent papers from 2024-2025"

**Zé:**
1. Logs feedback
2. Searches for relevant sections in LaTeX
3. Proposes: "Add 3-4 paragraphs after line 78, citing Smith (2024), Jones (2025)..."
4. Shows you the proposal

**You:**
> "Apply changes"

**Zé:**
1. Edits LaTeX
2. Compiles new PDF
3. Emails supervisor automatically (or asks who to send to)

**Result:** 3 minutes vs 30+ minutes manually

---

### **Use Case 2: Pre-Submission Polish**

**You (Obsidian Feedback Log):**
```markdown
### Active Feedback
- Abstract: Reduce to 250 words (currently 310)
- Introduction: Strengthen hypothesis statement
- Methodology: Add Figure 2 (data pipeline)
- Results: Highlight key findings in first paragraph
- Conclusion: Link back to research questions explicitly
- References: Format all URLs consistently
```

**Tell Zé:**
> "Process LAI feedback - final polish before submission"

**Zé:**
- Processes all 6 items
- Creates detailed proposals
- Marks each completed
- Final compile + email to co-authors

**Result:** Comprehensive revision in one pass

---

### **Use Case 3: Quick Typo Fix**

**You (Telegram):**
> "LAI paper: Fix typo on page 3 - 'teh' should be 'the'"

**Zé:**
- Quick fix (no approval needed for obvious typos)
- Compiles
- Updates log
- Optionally emails if configured

**Result:** 30 seconds

---

## 📊 Feedback Log Structure

### **Entry Example**

```markdown
### Revision 20260314-1430 - 2026-03-14 14:30

**Feedback:**
"Revise introduction paragraph 2 - make motivation clearer"

**Changes Proposed:**
- Line 45: Replace "However..." with "Nevertheless, existing approaches..."
- Line 47: Add citation to Smith et al. (2024)
- Line 48-50: Expand with concrete example from industry

**LaTeX Diff:**
\begin{verbatim}
- However, this approach has limitations.
+ Nevertheless, existing approaches \cite{Smith2024} face significant 
+ limitations in real-world deployment scenarios. For instance, recent 
+ industrial applications have shown...
\end{verbatim}

**Status:**
- [x] Received (2026-03-14 14:30)
- [x] Proposed (2026-03-14 14:35)
- [x] Approved (2026-03-14 14:40)
- [x] Implemented (2026-03-14 14:42)
- [x] Compiled (v1.2, 2026-03-14 14:43)
- [x] Emailed to supervisor@uni.edu (2026-03-14 14:44)

**Files:**
- Source: lai_paper_v1.2.tex
- PDF: lai_paper_v1.2.pdf (234 KB)
- Backup: lai_paper.tex.backup.20260314-144000

---
```

**All revisions tracked in one place** ✅

---

## 🔐 Safety Features

### **Automatic Backups**

Every edit creates a timestamped backup:
```
lai_paper.tex.backup.20260314-143000
lai_paper.tex.backup.20260314-150500
lai_paper.tex.backup.20260315-093000
```

**Rollback anytime:**
```bash
# List backups
ls -lah /path/to/paper/*.backup*

# Restore
cp lai_paper.tex.backup.YYYYMMDD-HHMMSS lai_paper.tex
```

### **Git Version Control**

If Git is initialized in paper folder:
```bash
cd /path/to/paper
git log --oneline
git diff HEAD~1  # See last change
git checkout <commit> -- lai_paper.tex  # Restore version
```

### **PDF Versioning**

All PDFs logged in Feedback Log:
- v1.0, v1.1, v1.2, etc.
- Or date-based: `lai_paper_2026-03-14.pdf`

---

## 🎛️ Configuration Options

### **Default Email Recipients**

Configure once, auto-use:
```bash
# In workflow script or tell Zé:
"Set LAI default recipients: supervisor@uni.edu, coauthor@institution.org"
```

**Zé will ask:**
> "Email to default recipients (supervisor, coauthor)? Or specify new?"

### **Auto-Email vs Manual**

**Auto-email** (after every compile):
- Fast iteration with supervisor
- Risk: Spam if many small changes

**Manual email** (you trigger):
- More control
- Better for final versions

**Configure:**
> "Zé, auto-email LAI paper after every compile to supervisor@uni.edu"  
> OR: "Zé, ask before emailing LAI paper"

---

## 📞 Telegram Command Reference

### **Feedback & Revision**
```
LAI paper: [your feedback]
LAI feedback: [your feedback]
```

### **Compilation**
```
LAI compile
Compile LAI paper
```

### **Email**
```
LAI email supervisor@uni.edu
Email LAI paper to [recipient]
```

### **Full Workflow**
```
LAI publish supervisor@uni.edu
Publish LAI paper to [recipient]
```

### **Status Check**
```
LAI status
Show LAI paper status
```

---

## ✅ Ready Checklist

Before first use:
- [ ] Read: `Projects/Academic Research/LAI Paper/Workflow Setup.md`
- [ ] Located .tex file
- [ ] Configured paths in `lai-paper-workflow.sh`
- [ ] Tested: `bash ~/clawd/scripts/lai-paper-workflow.sh status`
- [ ] Tested: `bash ~/clawd/scripts/lai-paper-workflow.sh compile`
- [ ] Tested: `bash ~/clawd/scripts/lai-paper-workflow.sh email [your-email]`
- [ ] Configured default recipients (optional)
- [ ] Tried one test feedback cycle

---

## 🚀 Quick Start

1. **Setup** (5 minutes):
   - Find .tex file location
   - Update script paths
   - Test compile + email

2. **First Use**:
   - Telegram: "LAI paper: [small test change]"
   - Zé proposes
   - You approve
   - PDF arrives in inbox

3. **Daily Use**:
   - Feedback via Telegram (fast)
   - OR Obsidian (detailed)
   - Zé handles rest

**You focus on research. Zé handles the tedious stuff.** 😌

---

**Created:** 2026-03-14  
**By:** Zé  
**For:** Théo  
**Next:** Complete setup checklist in Workflow Setup guide
