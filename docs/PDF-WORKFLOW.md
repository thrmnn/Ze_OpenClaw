# PDF Workflow with Zé

## How to Share PDFs

### Option 1: Direct File Path (Recommended)
If PDF is on your system:
```
"Hey Zé, extract info from my resume: /path/to/resume.pdf"
```

### Option 2: Upload to Obsidian Vault
Save PDF in vault:
```
/mnt/c/Users/theoh/OneDrive/Documents/Obsidian Vault/Resources/Documents/resume.pdf
```

Then tell Zé:
```
"Process my resume PDF in Resources/Documents/resume.pdf"
```

### Option 3: Web Link
If PDF is online:
```
"Analyze this PDF: https://example.com/document.pdf"
```

---

## What Zé Can Do with PDFs

### 1. Resume/CV Extraction
**Command:** "Extract career info from [PDF]"

**Zé will:**
- Extract work experience, education, skills
- Populate `Resources/Career Experience Base.md`
- Structure information for job pipeline
- Identify keywords and achievements

### 2. Academic Paper Analysis
**Command:** "Analyze this paper: [PDF]"

**Zé will:**
- Extract key findings, methodology
- Summarize for literature reviews
- Add to project notes
- Identify citations to follow up

### 3. Document Summarization
**Command:** "Summarize [PDF]"

**Zé will:**
- Provide structured summary
- Extract action items
- Create reference note in Obsidian

### 4. Data Extraction
**Command:** "Extract [specific info] from [PDF]"

**Zé will:**
- Pull specific data points
- Structure in requested format
- Add to relevant project notes

---

## Technical Details

**PDF Tool:** OpenClaw's `pdf` tool
- Supports native PDF analysis (Anthropic models)
- Text/image extraction fallback
- Up to 10 PDFs at once
- Page range selection available

**Example:**
```
pdf(pdf="/path/to/file.pdf", prompt="Extract work experience", pages="1-3")
```

---

## Resume Processing Workflow

1. **You:** Share resume PDF path
2. **Zé:** Extracts all career information
3. **Zé:** Populates `Career Experience Base.md`
4. **You:** Review and fill gaps
5. **Zé:** Uses as foundation for:
   - Tailored resumes per job
   - Cover letter generation
   - Job application automation

---

## Best Practices

- ✅ PDFs up to 50MB work fine
- ✅ Text-based PDFs extract better than scanned images
- ✅ Specify page ranges for large documents
- ✅ Ask Zé to structure output in Obsidian format
- ❌ Don't share sensitive docs in public channels

---

**Ready to process your resume? Just share the path!**
