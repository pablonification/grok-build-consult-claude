---
name: consult-claude
description: >
  Read-only second opinion from Claude Code (claude -p). Use when the user
  explicitly asks ("ask Claude", "second opinion", "/consult-claude") OR when
  a HARD GATE passes: high-stakes architecture/security decisions, 2+ credible
  approaches with real trade-offs, or blocked after 2+ distinct attempts.
  Modes: plan, review, advice. Do NOT use for routine coding, debugging,
  file edits, or "just to be thorough". Grok implements any follow-up changes.
user-invocable: true
argument-hint: "[plan|review|advice] [--model opus|sonnet|fable] [question]"
---

# Consult Claude (read-only)

Grok Build stays primary. Claude Code is an expensive **advisor only** — never an implementer.

<HARD-GATE>
Do NOT consult unless **one** of these is true:

1. **Explicit** — user asked for Claude's opinion, second opinion, or ran `/consult-claude`.
2. **Implicit** — ALL of:
   - Stakes are high (wrong choice wastes significant time, or touches security/auth/data/migrations/concurrency), AND
   - Genuinely uncertain (2+ credible approaches, or stuck after 2+ **distinct** attempts on the same blocker), AND
   - Not answerable from repo/docs alone without gambling.

If the gate fails, continue as Grok. Do not consult "to be safe."
</HARD-GATE>

## Limits

- **Read-only** — Claude must not edit files. Grok applies changes if needed.
- **Max 1 implicit consult per user task** unless the user asks again.
- **No consult loops** — do not ping-pong Grok ↔ Claude repeatedly.
- **Log the reason** — always tell the user why Claude was consulted.

## Model selection (always latest family alias)

Pass `--model <alias>` to the wrapper. Aliases resolve to the latest model in each family (e.g. `opus` → current Opus, `sonnet` → current Sonnet, `fable` → current Fable). **Never** hardcode dated model IDs.

| Alias | Use when |
|-------|----------|
| **opus** | Architecture with hard trade-offs, security/auth threat modeling, concurrency/distributed design, ambiguous high-stakes decisions, deep review of a large risky change |
| **sonnet** | Plan critique, code/design review, implementation approach comparison, "is this plan sound?", medium-scope advice where speed/cost matter |
| **fable** | Greenfield product shape, UX/flow exploration, creative alternatives, early brainstorming before commitment — exploratory, not final security sign-off |

**Default if unsure:** `sonnet` for review/plan modes; `opus` for advice when security or irreversible architecture is involved; `fable` only when exploring options, then re-consult with `opus` or `sonnet` before committing.

Override with `--model` when the user requests a specific family.

## Invocation

```
/consult-claude plan [question]
/consult-claude review [question]
/consult-claude advice [question]
/consult-claude review --model opus
/consult-claude                    # infer mode from context; ask if unclear
```

## Orchestration steps

Resolve paths once at start:

```
SKILL_DIR   = <dirname of this SKILL.md>
CONSULT_SH  = ${SKILL_DIR}/scripts/consult.sh
RUBRIC      = ${SKILL_DIR}/references/gating-rubric.md
PROMPTS_DIR = ${SKILL_DIR}/references/prompts
```

### 1. Gate

- If implicit: read `${RUBRIC}`, confirm the gate passes, write a one-sentence **consult reason**.
- If explicit: skip gate but still use read-only wrapper.

### 2. Choose mode and model

| Mode | Purpose | Prompt template |
|------|---------|-------------------|
| `plan` | Critique or compare approaches before implementation | `${PROMPTS_DIR}/plan.md` |
| `review` | Review diff, design, or current code state | `${PROMPTS_DIR}/review.md` |
| `advice` | Unblock a specific decision or failure | `${PROMPTS_DIR}/advice.md` |

Pick model per table above. State mode, model alias, and reason in your reply preamble.

### 3. Assemble context bundle

Build a focused prompt (not the whole repo):

- **Goal** — one sentence
- **Open question** — what Claude must answer
- **Grok's current position** — draft plan, hypothesis, or summary (ask Claude to *critique*, not restart)
- **Relevant files** — paths and contents (only what matters; cap ~30k chars unless user asked for more)
- **Constraints** — stack, non-goals, deadlines
- **Attempt history** (advice mode) — what was tried and what failed

Write the assembled prompt to a temp file, e.g. `/tmp/consult-claude-prompt-$$.md`.

### 4. Run consult (blocking)

From the **workspace root** of the project under discussion:

```bash
"${CONSULT_SH}" \
  --mode <plan|review|advice> \
  --model <opus|sonnet|fable> \
  --workspace "<absolute-workspace-path>" \
  --prompt-file "/tmp/consult-claude-prompt-$$.md" \
  --reason "<consult reason>"
```

- Set `block_until_ms` ≥ 120000 (Claude can take 30–90s).
- Do not background this unless the user asked to wait asynchronously.
- On non-zero exit: report stderr; do not pretend the consult succeeded.

### 5. Read output

The script prints JSON to stdout and writes artifacts under `/tmp/consult-claude-<run_id>/`:

| File | Contents |
|------|----------|
| `result.json` | Full Claude `--output-format json` payload |
| `response.txt` | Human-readable reply text |
| `pre-snapshot.txt` | `git status` before consult |
| `post-snapshot.txt` | `git status` after consult |
| `files-changed.txt` | Paths that changed (should be empty) |

Read `response.txt` and `files-changed.txt`. If `files-changed.txt` is non-empty, **warn the user** — Claude was supposed to be read-only.

### 6. Synthesize (Grok owns the decision)

Do not dump Claude's reply verbatim. Provide:

1. **Consult meta** — mode, model alias, reason, cost if present in JSON
2. **Claude's assessment** — concise summary
3. **Agreement** — what Grok accepts
4. **Disagreement** — what Grok rejects and why (repo context Grok has that Claude may not)
5. **Recommended next step** — Grok executes changes, not Claude

## What NOT to pass to Claude

- Entire monorepos or node_modules
- Secrets, API keys, tokens (redact first)
- Vague "what do you think?" without Grok's draft position
- Tasks Grok can resolve with one file read or a test run

## Error handling

| Situation | Action |
|-----------|--------|
| `claude` not found | Tell user to install Claude Code; stop |
| Auth failure | Tell user to run `claude` interactively to refresh login |
| Timeout | Retry once with `sonnet`; if still failing, report and continue as Grok |
| Unexpected file changes | Show diff summary; do not auto-apply; ask user |