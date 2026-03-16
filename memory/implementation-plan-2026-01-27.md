# Implementation Plan - 2026-01-27 23:05

## Tasks (Sequential Execution)

### Task 1: Drive Write Scope ⏱️ 5 min
**Goal:** Enable document creation capability

**Steps:**
1. Update OAuth scope in auth script to include `drive.file`
2. Delete existing tokens
3. Generate new OAuth URL
4. Wait for user authorization code (BLOCKING - needs user)
5. Exchange code for new tokens
6. Verify: Create test document
7. Mark complete in Trello

**Verification:**
- [ ] New tokens saved with drive.file scope
- [ ] Test document created successfully
- [ ] Document shared with user

**Dependencies:** User must provide OAuth code (1-2 min)

---

### Task 2: Multilingual Interface ⏱️ 15 min
**Goal:** Support FR/EN/PT language switching

**Steps:**
1. Create language detection logic
2. Add language preference to USER.md
3. Update response formatting for each language
4. Test with French input
5. Test with Portuguese input
6. Document usage in TOOLS.md
7. Mark complete in Trello

**Verification:**
- [ ] French message → French response
- [ ] Portuguese message → Portuguese response
- [ ] English message → English response
- [ ] Language preference persists

**Dependencies:** None (fully autonomous)

---

### Task 3: X AI Voices Monitoring ⏱️ 30 min
**Goal:** Daily AI field updates in morning brief

**Approach:** Start with Nitter RSS (no auth needed)

**Steps:**
1. Check if user provided voices list
   - IF YES: Proceed
   - IF NO: Create placeholder system, mark as "awaiting voices list"
2. Install RSS parser dependencies
3. Create voice monitoring script (Nitter RSS)
4. Test fetch from sample AI voice (e.g., @karpathy)
5. Create summarization function
6. Integrate with morning-brief.sh
7. Update cron job
8. Test end-to-end
9. Mark complete in Trello

**Verification:**
- [ ] RSS fetch working for test voices
- [ ] Summary generated (3-5 bullets)
- [ ] Morning brief includes AI updates section
- [ ] Cron job updated successfully

**Dependencies:** 
- Ideally: User provides voices list
- Fallback: Use sample voices, document "awaiting user list"

---

## Execution Strategy

### Phase 1: Drive Scope (NEEDS USER)
```
START → Update auth script → Generate OAuth URL → 
PAUSE (send URL to user) → WAIT for code → 
Exchange tokens → Test → COMPLETE
```

**Blocking point:** OAuth authorization (user clicks link, sends code)

### Phase 2: Multilingual (AUTONOMOUS)
```
START → Detect language → Update configs → 
Test FR/EN/PT → Document → COMPLETE
```

**Blocking:** None

### Phase 3: X Monitoring (AUTONOMOUS*)
```
START → Check voices list → 
IF NO LIST: Use samples + mark "pending input" →
Install deps → Build script → Test → Integrate → COMPLETE
```

**Blocking:** Ideally needs voices list, but can proceed with samples

---

## Optimal Order

**Option A (User Available):**
1. Drive scope (with user for OAuth)
2. Multilingual (while Drive is testing)
3. X monitoring (autonomous)

**Option B (User Busy):**
1. Multilingual (autonomous)
2. X monitoring (autonomous, use samples)
3. Drive scope (when user available for OAuth)

**Recommendation:** Start with Multilingual + X (autonomous), pause Drive at OAuth step

---

## Progress Tracking

**State file:** `memory/task-progress.json`

```json
{
  "session": "2026-01-27-23:05",
  "tasks": {
    "drive-scope": {
      "status": "pending|in-progress|blocked|complete",
      "step": "current step name",
      "blockedReason": "awaiting OAuth code",
      "verification": {}
    },
    "multilingual": {
      "status": "pending",
      "verification": {}
    },
    "x-monitoring": {
      "status": "pending",
      "verification": {}
    }
  }
}
```

---

## Rollback Plan

**If task fails:**
1. Log error to `memory/task-errors.json`
2. Restore previous state
3. Mark as "failed" in Trello comment
4. Report to user with details

---

## Final Verification

**All tasks complete when:**
- [ ] Drive: Document created + shared
- [ ] Multilingual: All 3 languages tested
- [ ] X monitoring: AI updates in morning brief
- [ ] Trello: All 3 items checked
- [ ] User notified: Summary of changes

---

## Estimated Timeline

**Sequential (no parallelization):**
- Drive scope: 5 min (+ user OAuth wait time)
- Multilingual: 15 min
- X monitoring: 30 min
**Total:** ~50 min + OAuth wait

**With optimal order:**
- Multilingual + X: ~45 min (parallel thinking, sequential execution)
- Drive: 5 min when user returns
**Total:** ~50 min spread over user availability

---

## User Instructions During Execution

**You can:**
- Give new instructions
- Ask for status updates
- Interrupt if needed

**I will:**
- Execute autonomously
- Pause at blocking points (OAuth)
- Report progress every 10 min
- Verify each completion
- Update you at end

---

**Ready to execute?** Say "go" or "start" and I'll begin with autonomous tasks first (Multilingual → X monitoring), then pause for Drive OAuth when ready.
