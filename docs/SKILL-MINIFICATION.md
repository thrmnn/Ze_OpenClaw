# SKILL Minification Guide

## Overview

Minified skills (`.min.md`) provide token-efficient versions of full skill documentation for subagent spawning and context-constrained scenarios.

## Token Savings

| Skill | Original | Minified | Reduction | Status |
|-------|----------|----------|-----------|--------|
| **github** | 1,113 bytes | 519 bytes | **53.4%** | ✅ |
| **trello** | 2,651 bytes | 1,144 bytes | **56.9%** | ✅ |
| **convex-vercel-deploy** | 5,308 bytes | 1,076 bytes | **79.8%** | ✅ |
| **weather** | 2,291 bytes | 647 bytes | **71.8%** | ✅ |

**Average reduction: 65.5%**

## When to Use Each Version

### Use Full SKILL.md When:
- First time learning a skill
- Debugging issues (needs troubleshooting section)
- Complex scenarios requiring examples
- Training new agents
- Understanding context and rationale

### Use SKILL.min.md When:
- Spawning subagents with limited token budget
- Agent already knows the skill basics
- Quick reference lookup
- Batch operations (multiple skills loaded)
- Mobile/telegram contexts where brevity matters

## Minification Guidelines

### What to Keep ✅
- **Core instructions** - Essential workflow steps
- **Critical commands** - Most-used patterns with syntax
- **Constraints** - Important don'ts and gotchas
- **Setup requirements** - Credentials, prerequisites
- **Quick reference** - Command templates
- **Frontmatter** - Name, description, metadata

### What to Remove ❌
- **Verbose explanations** - "This is useful because..."
- **Multiple examples** - Keep 1-2 max, remove variations
- **Background info** - History, alternatives, comparisons
- **Troubleshooting sections** - Move to full docs
- **Lengthy descriptions** - Use bullet points
- **Redundant patterns** - Consolidate similar commands

### Formatting Best Practices
- Use code blocks for commands (easier to copy)
- Bullet lists > paragraphs
- Bold for emphasis > headers for subsections
- Inline code for values: `` `prod:xxx` ``
- One-liners for simple commands
- Group related commands together

## Creating New Minified Skills

1. **Read the full SKILL.md** - Understand core purpose
2. **Identify essential commands** - What's used 80% of the time?
3. **Strip explanations** - Keep syntax, remove "why"
4. **Test the minified version** - Can you complete common tasks?
5. **Aim for 50-70% reduction** - More if verbose original
6. **Keep frontmatter** - Metadata helps agent selection

### Template Structure
```markdown
---
name: skill-name
description: "One-liner description"
---

# Skill Name (Minified)

**Setup:** Brief setup if needed

## Core Commands
\`\`\`bash
# Essential patterns only
command --flag value
\`\`\`

**Key constraints or rate limits**
```

## Testing Minified Skills

Test by spawning a subagent with the minified skill:
```bash
# Read minified skill and perform common task
cat ~/clawd/skills/github/SKILL.min.md
# Then attempt: list PRs, check CI status, view logs
```

If the agent can complete 80% of common tasks, the minification is successful.

## Maintenance

- **Update both versions** when skills change
- **Review quarterly** - Remove outdated info from .min files
- **Check token counts** - Aim to maintain 50%+ reduction
- **Test after updates** - Ensure .min still functional

## Future Candidates for Minification

High-value targets (verbose originals):
- **job-auto-apply** - Large skill, would benefit
- **email** - Potentially complex
- **calendar** - If workflow-heavy
- **obsidian** - Depending on usage patterns

Low-priority (already concise):
- **sag** - Already minimal
- **notion** - Moderate size
- **tmux** - Specialized use

## Example: Before vs After

### Before (Full github/SKILL.md excerpt)
```markdown
## Pull Requests

Check CI status on a PR:
\`\`\`bash
gh pr checks 55 --repo owner/repo
\`\`\`

List recent workflow runs:
\`\`\`bash
gh run list --repo owner/repo --limit 10
\`\`\`

View a run and see which steps failed:
\`\`\`bash
gh run view <run-id> --repo owner/repo
\`\`\`
```

### After (Minified)
```markdown
## Pull Requests
\`\`\`bash
gh pr checks 55 --repo owner/repo
gh run list --repo owner/repo --limit 10
gh run view <run-id> --repo owner/repo --log-failed
\`\`\`
```

**Reduction method:** Consolidated commands, removed explanatory text, kept syntax.

---

**Created:** 2026-02-26  
**Last Updated:** 2026-02-26  
**Token Budget Impact:** ~65% reduction across 4 priority skills
