# Advice consult prompt template

Grok fills each section before calling `consult.sh --mode advice`.

---

## Goal

<!-- One sentence -->

## Blocker / decision

<!-- The specific thing Grok cannot resolve confidently -->

## What Grok already tried

<!-- Attempt 1: ... outcome -->
<!-- Attempt 2: ... outcome -->

## Grok's best guess

<!-- Current hypothesis — Claude should validate or correct -->

## Relevant context

### Error messages / logs (if any)

```
```

### Relevant files

<!-- Path + excerpt -->

## What Claude should return

1. Direct answer to the open question
2. Root cause analysis (if debugging)
3. Recommended next steps in priority order
4. What Grok should **not** do
5. Risks if we proceed with Grok's current guess