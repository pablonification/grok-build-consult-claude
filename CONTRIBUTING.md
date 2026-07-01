# Contributing

## Commits

This project uses [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | When |
|------|------|
| `feat` | New capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes nor adds features |
| `test` | Tests |
| `chore` | Tooling, deps, housekeeping |

### Examples

```
feat: add fable model guidance to SKILL.md
fix(consult): enforce timeout on macOS without coreutils
docs: clarify install symlink steps
```

### Rules

- Use imperative mood in the description: `add` not `added`
- No period at the end of the subject line
- Keep subject ≤ 72 characters
- Scope is optional but encouraged for script/skill changes: `fix(consult)`, `feat(skill)`

## Pull requests

1. Branch from `main`
2. Use conventional commit messages
3. Test `consult.sh` with a minimal prompt before opening a PR
4. Keep Claude consults read-only — Grok implements follow-ups