# grok-build-consult-claude

A [Grok Build](https://github.com/xai-org/grok) skill that consults **Claude Code** (`claude -p`) for read-only second opinions — plan critique, code review, or advice — only when you ask explicitly or when a strict gate passes.

Grok Build stays primary. Claude advises. Grok implements.

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
skills/consult-claude/
├── SKILL.md                      # orchestrator + gating rules
├── scripts/consult.sh            # read-only claude -p wrapper
└── references/
    ├── gating-rubric.md
    └── prompts/{plan,review,advice}.md
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## License

MIT — see [LICENSE](LICENSE).