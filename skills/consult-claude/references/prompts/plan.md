# Plan consult prompt template

Grok fills each section before calling `consult.sh --mode plan`.

---

## Goal

<!-- One sentence: what we are trying to build or decide -->

## Open question for Claude

<!-- Specific question, e.g. "Is approach A or B better given constraints X?" -->

## Grok's proposed plan (critique this)

<!-- Grok's draft — approaches, steps, files to touch. Claude should improve, not replace blindly. -->

## Relevant context

### Constraints

<!-- Stack, deadlines, non-goals, compatibility requirements -->

### Relevant files

<!-- Path + summary or excerpt for each file that matters -->

## What Claude should return

1. Assessment of Grok's plan (sound / risky / flawed)
2. Trade-off comparison if multiple approaches exist
3. Concrete risks and missing edge cases
4. One recommended path forward
5. What Grok should verify before implementing