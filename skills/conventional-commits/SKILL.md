---
name: conventional-commits
description: >
  Write git commit messages using Conventional Commits v1.0.0. Invoke when
  committing, staging for commit, amending, rebasing commit messages, or when
  the user asks for feat:/fix:/docs: format. Do NOT load for unrelated coding tasks.
user-invocable: true
argument-hint: "[optional context for the commit]"
---

# Conventional Commits

Use [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) for **every** git commit you create.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type | Use for |
|------|---------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Restructure without feat/fix |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Build, deps, tooling |
| `ci` | CI/CD changes |

## Rules

- Imperative mood: `add handler` not `added handler`
- No trailing period on the subject line
- Subject ≤ 72 characters
- Scope when helpful: `fix(consult):`, `feat(auth):`
- Breaking changes: footer `BREAKING CHANGE: <description>`

## Examples

```
feat: add consult-claude skill
fix(consult): block Bash via allow-list tools
docs: add install instructions to README
chore: bump dependency
```

## Workflow

1. Review staged changes (`git diff --cached` or `git status`)
2. Pick type and optional scope from the diff
3. Write subject that states **what** changed, not **how** you feel about it
4. Add body only if context helps future readers
5. Run `git commit -m "type(scope): subject"` or heredoc for body

When amending or rebasing, rewrite messages to match this format.