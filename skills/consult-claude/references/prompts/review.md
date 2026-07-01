# Review consult prompt template

Grok fills each section before calling `consult.sh --mode review`.

---

## Goal

<!-- What this change is supposed to accomplish -->

## Open question for Claude

<!-- e.g. "Is this safe to merge?" or "What did we miss?" -->

## Scope under review

<!-- PR summary, branch name, or list of files/commits -->

## Grok's review notes (optional)

<!-- What Grok already noticed — ask Claude to add, not duplicate -->

## Diff or code excerpts

```
<!-- git diff, or pasted excerpts with file paths -->
```

## What Claude should return

1. Findings by severity: critical / major / minor
2. File paths and line references where possible
3. Security and correctness concerns first
4. Whether this is merge-ready from a review perspective
5. Suggested fixes (text only — Grok will implement)