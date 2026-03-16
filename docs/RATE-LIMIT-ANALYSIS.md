# Rate Limit Analysis & Optimization Plan

**Date:** 2026-02-25  
**Context:** Analysis of subagent spawn failures due to Anthropic API rate limits

---

## 1. Rate Limit Estimation

### Agent Performance Data

| Agent | Runtime | Tokens (in/out) | Prompt/Cache | Total Tokens | Tokens/Second |
|-------|---------|-----------------|--------------|--------------|---------------|
| mc-debugger | 22s | 37/708 (745) | 54,400 | 55,145 | ~2,507 |
| convex-vercel-skill | 9s | 10/299 (309) | 16,600 | 16,909 | ~1,879 |
| **Combined** | ~22-31s | 1,054 | 71,000 | **72,054** | N/A |

### Rate Limit Hypothesis

**Observed Behavior:**
- Both agents hit "API rate limit reached" 
- Combined token load: ~72k tokens in <31s window
- Both spawned in parallel or near-parallel

**Anthropic API Tier Estimates:**

| Tier | Requests/Min | Tokens/Min | Tokens/Sec | Assessment |
|------|--------------|------------|------------|------------|
| Tier 1 | 50 | 40,000 | 666 | **Most likely** - 72k exceeds 40k/min |
| Tier 2 | 1,000 | 80,000 | 1,333 | Possible - close to limit |
| Tier 3 | 2,000 | 160,000 | 2,666 | Unlikely - well under limit |

**Conclusion:** The account is likely on **Tier 1 (40k tokens/min)** or **Tier 2 (80k tokens/min)**.

**Scope:** Per-API-key (OpenRouter confirms per-key limits for Anthropic models)

---

## 2. Optimization Strategies

### A. Prompt Compression Techniques

**Problem:** Large prompt/cache sizes (54.4k, 16.6k) burn through token budget

**Solutions:**

1. **Context Pruning**
   - Remove non-essential project context files for subagents
   - Load only task-specific skills, not entire workspace
   - Strip out examples/documentation from SKILL.md files when passing to agents
   
2. **Lazy Loading**
   - Don't load MEMORY.md, USER.md, SOUL.md for sub-agents
   - Load only AGENTS.md + task description + relevant skill
   - Target: <10k prompt tokens per subagent

3. **Skill Minification**
   - Create `.min.md` versions of skills with examples removed
   - Keep only essential instructions and commands
   - Estimated savings: 30-50% per skill

4. **Token Budget Header**
   - Add to subagent prompt: "Token budget: 5k tokens. Be concise."
   - Enforce brevity in task descriptions

### B. Optimal Cache Usage Patterns

**Current Issue:** Cache hits still count toward rate limits

**Best Practices:**

1. **Cache Stability**
   - Keep workspace context stable across spawns
   - Don't modify AGENTS.md/SOUL.md during active spawns
   - Cache benefits: Faster response, but NO rate limit relief

2. **Cache Invalidation Awareness**
   - Each context change invalidates cache
   - Batch workspace updates between spawn waves

3. **Cache ≠ Free Tokens**
   - Cached tokens still count toward rate limits
   - Focus on reducing total context, not just cache hits

### C. Sequential vs Parallel Spawn Strategies

**Parallel Spawning (Current - RISKY):**
- ✗ Agents stack token usage (72k combined)
- ✗ All hit rate limit together
- ✗ Unpredictable total load
- ✓ Faster completion (if successful)

**Sequential Spawning (SAFE):**
- ✓ Predictable token usage
- ✓ Stay under per-minute limit
- ✓ No cascading failures
- ✗ Slower total completion time

**Hybrid Strategy (RECOMMENDED):**
1. **Token-Aware Batching:**
   - Calculate token budget per agent
   - Spawn in waves that fit within rate limit
   - Example: 2 agents @ 20k tokens = 40k (safe for Tier 1)

2. **Priority Queuing:**
   - High-priority tasks spawn immediately
   - Low-priority tasks wait for token budget refresh
   - Main agent monitors token usage and gates spawns

3. **Staggered Launch:**
   - Spawn agent 1 → wait 15s → spawn agent 2
   - Spreads token load across time windows

### D. Token Budget Allocation

**Tier 1 Budget (40k tokens/min):**
- Main agent: 10k tokens/min (25%) → monitoring, coordination
- Subagent pool: 30k tokens/min (75%) → task execution

**Per-Agent Budgets:**

| Agent Type | Max Prompt | Max Output | Total Budget | Agents/Min |
|------------|-----------|------------|--------------|------------|
| Simple (debug, test) | 10k | 2k | 12k | 3 |
| Standard (skill work) | 20k | 5k | 25k | 1 |
| Complex (analysis) | 30k | 10k | 40k | 1 |

**Buffer:** Reserve 5k tokens/min for main agent responsiveness

---

## 3. Spawn Planning Formula

### A. Maximum Parallel Agents

```
Max_Parallel = floor(Rate_Limit_Tokens / Avg_Agent_Tokens)
```

**For Tier 1 (40k tokens/min):**
- Simple agents (12k): `40k / 12k = 3 agents`
- Standard agents (25k): `40k / 25k = 1 agent`
- Mixed (1 standard + 1 simple): `25k + 12k = 37k` ✓

**Safety Factor:** Multiply by 0.75 to account for variance
- **Safe Parallel Limit: 2 standard agents OR 2 simple agents**

### B. Task Size Limits

**Small Task (<15k tokens):**
- Duration: <30s
- Examples: Quick tests, simple queries, file operations
- Strategy: Can spawn 2 in parallel

**Medium Task (15-30k tokens):**
- Duration: 30s-2min
- Examples: Skill execution, debugging, analysis
- Strategy: Spawn 1 at a time, wait for completion

**Large Task (>30k tokens):**
- Duration: >2min
- Examples: Complex analysis, multi-step workflows
- Strategy: Break into subtasks OR allocate full budget

### C. Token Budget Per Agent Type

```javascript
// Pseudo-code for spawn decision
function canSpawn(agentType, currentLoad) {
  const budgets = {
    simple: 12000,
    standard: 25000,
    complex: 40000
  };
  
  const rateLimit = 40000; // tokens per minute
  const buffer = 5000;
  const availableBudget = rateLimit - currentLoad - buffer;
  
  return availableBudget >= budgets[agentType];
}

// Example usage:
currentLoad = 15000; // main agent + active subagent
canSpawn('simple', currentLoad); // 40k - 15k - 5k = 20k ✓ (12k < 20k)
canSpawn('standard', currentLoad); // 20k ✗ (25k > 20k)
```

### D. Spawn Queue Implementation

**Recommended Architecture:**

1. **Token Monitor:**
   - Track total tokens used in rolling 60s window
   - Calculate available budget in real-time

2. **Spawn Queue:**
   - Queue agents when budget insufficient
   - Priority: urgent > standard > background

3. **Auto-Release:**
   - When agent completes, release its token budget
   - Check queue and spawn next if budget available

4. **Backoff Strategy:**
   - On rate limit error: wait 15s before retry
   - Exponential backoff: 15s → 30s → 60s

---

## 4. Immediate Action Items

### Priority 1: Reduce Subagent Context
- [ ] Create minimal AGENTS.md variant for subagents (remove examples)
- [ ] Don't load MEMORY.md, USER.md, SOUL.md for subagents
- [ ] Target: <10k prompt tokens per spawn

### Priority 2: Implement Sequential Spawning
- [ ] Add spawn queue to main agent logic
- [ ] Implement token budget tracking (rolling 60s window)
- [ ] Gate parallel spawns based on available budget

### Priority 3: Task Classification
- [ ] Tag tasks as simple/standard/complex before spawning
- [ ] Estimate token budget per task type
- [ ] Reject or queue tasks when budget insufficient

### Priority 4: Monitoring
- [ ] Log token usage per spawn to `logs/token-usage.jsonl`
- [ ] Dashboard view of token consumption
- [ ] Alert when approaching rate limits

---

## 5. Success Metrics

**Before Optimization:**
- Parallel spawn success rate: ~0% (both failed)
- Token efficiency: 72k for 2 agents (36k avg)

**After Optimization (Targets):**
- Parallel spawn success rate: >95%
- Token efficiency: <15k per simple agent, <25k per standard agent
- Rate limit errors: <1% of spawns
- Queue wait time: <30s avg

---

## 6. References

- Anthropic API Documentation: https://docs.anthropic.com/en/api/rate-limits
- OpenRouter Rate Limits: Per-key, model-specific
- Token Counting: Input + Output + Cached (all count toward limits)

---

**Next Steps:**
1. Implement Priority 1 changes (context reduction)
2. Test spawn with minimal context
3. Add token budget tracking
4. Deploy spawn queue logic
5. Monitor and iterate

**Estimated Impact:** 50-70% reduction in rate limit errors, 2-3x more agents per minute capacity.
