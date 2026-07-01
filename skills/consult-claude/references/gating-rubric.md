# Consult Claude — gating rubric

Use this only for **implicit** consults. Explicit user requests skip the gate but stay read-only.

## Consult YES (need at least one)

### High-stakes uncertainty
- 2+ **credible** approaches with meaningfully different trade-offs
- Wrong choice likely wastes **>30 minutes** of user time or requires rework
- Touches **security**, **auth**, **payments**, **PII**, **migrations**, or **distributed/concurrent** behavior

### Genuine block
- **2+ distinct** attempts on the **same** blocker failed (not the same mistake repeated)
- Grok cannot resolve with a targeted read, test, or doc lookup without gambling

### Review before merge (large/risky)
- Diff is large or spans critical paths and user has not asked for speed over safety
- Pre-merge architecture sanity check on an irreversible decision

## Consult NO

- Routine feature work with an obvious implementation path
- Single-file bugfix, typo, config tweak, dependency bump
- User said "just do it", "quick fix", "don't overthink"
- Factual question answerable from repo, tests, or docs
- "Would be nice to double-check" — not sufficient
- Already consulted implicitly once this task (unless user asks again)
- Grok has not formed a draft position yet (do homework first, then consult)

## Implicit consult checklist (all must be true)

1. [ ] Stakes match "Consult YES" above
2. [ ] Grok has a **draft** plan/hypothesis to critique (not blank-slate outsourcing)
3. [ ] Context bundle can be assembled in **<30k chars** of relevant material
4. [ ] Expected value of consult > cost + latency (Claude is expensive)
5. [ ] Grok will **synthesize** — not defer judgment to Claude

If any box fails → **do not consult**.

## Model pick (quick reference)

| Situation | Alias |
|-----------|-------|
| Security, irreversible architecture, deep ambiguity | `opus` |
| Plan/diff review, approach comparison | `sonnet` |
| Greenfield exploration, UX/product shape brainstorming | `fable` |

Always pass the family **alias** (`opus`, `sonnet`, `fable`) — never a dated model ID.