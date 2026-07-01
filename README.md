# grok-build-skills

Grok Build skills for safer, more disciplined agent workflows.

| Skill | Purpose |
|-------|---------|
| [`consult-claude`](skills/consult-claude/) | Read-only second opinions from Claude Code (`claude -p`) |
| [`conventional-commits`](skills/conventional-commits/) | `feat:` / `fix:` / `docs:` commit messages on demand |

### consult-claude

Consults **Claude Code** for plan critique, code review, or advice — only when you ask explicitly or when a strict gate passes. Grok Build stays primary. Claude advises. Grok implements.

## Features

- **Read-only** — allow-listed tools only (`Read`, `Grep`, `Glob`); no file edits by Claude
- **Strict gating** — avoids expensive reflexive consults
- **Three modes** — `plan`, `review`, `advice`
- **Model aliases** — `opus`, `sonnet`, `fable` (always latest in each family)
- **Post-flight checks** — workspace diff snapshot + `is_error` handling

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated (`claude --version`)
- Grok Build with skills support

## Install

### Option A — symlink (recommended for local dev)

```bash
git clone https://github.com/pablonification/grok-build-consult-claude.git
ln -sfn "$(pwd)/grok-build-consult-claude/skills/consult-claude" ~/.grok/skills/consult-claude
ln -sfn "$(pwd)/grok-build-consult-claude/skills/conventional-commits" ~/.grok/skills/conventional-commits
```

### Option B — copy into a project

```bash
mkdir -p /path/to/your/project/.grok/skills
cp -R skills/consult-claude /path/to/your/project/.grok/skills/
```

Grok discovers skills from `~/.grok/skills/`, `<repo>/.grok/skills/`, or cwd `.grok/skills/`.

## Usage

Slash command:

```
/consult-claude plan
/consult-claude review
/consult-claude advice
/consult-claude review --model opus
```

Natural language:

> "Ask Claude for a second opinion on this architecture"

Or invoke implicitly when the skill's HARD GATE passes (max once per task).

## Model selection

| Alias | Use when |
|-------|----------|
| `opus` | Security, irreversible architecture, hard trade-offs |
| `sonnet` | Plan/diff review, approach comparison (default) |
| `fable` | Greenfield exploration, UX/product brainstorming |

## Manual test

```bash
chmod +x skills/consult-claude/scripts/consult.sh

cat > /tmp/prompt.md <<'EOF'
## Goal
Smoke test.

## Open question
Reply with exactly: OK
EOF

skills/consult-claude/scripts/consult.sh \
  --mode advice \
  --model sonnet \
  --workspace . \
  --prompt-file /tmp/prompt.md \
  --reason "manual test"
```

## Repository layout

```
skills/
├── consult-claude/                 # Claude Code second opinions
│   ├── SKILL.md
│   ├── scripts/consult.sh
│   └── references/
└── conventional-commits/           # feat:/fix:/docs: on demand (not global AGENTS.md)
    └── SKILL.md
```

**Why skills over global AGENTS.md?** Skills load only when committing or when you invoke them — they don't pollute every session's context.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## License

MIT — see [LICENSE](LICENSE).