#!/usr/bin/env bash
# Read-only Claude Code consult wrapper for Grok Build.
set -euo pipefail

MODE=""
MODEL="sonnet"
WORKSPACE="$(pwd)"
PROMPT_FILE=""
REASON=""
TIMEOUT_MS=120000

usage() {
  cat <<'EOF'
Usage: consult.sh --mode <plan|review|advice> --prompt-file <path> [options]

Options:
  --model <opus|sonnet|fable>   Model family alias (default: sonnet)
  --workspace <path>            Workspace root (default: cwd)
  --reason <text>               Why this consult was triggered
  --timeout-ms <ms>             Max wait hint for orchestrator (default: 120000)
  -h, --help                    Show this help

Read-only: disallows Edit/Write tools. Grok Build applies any changes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    --model) MODEL="${2:-}"; shift 2 ;;
    --workspace) WORKSPACE="${2:-}"; shift 2 ;;
    --prompt-file) PROMPT_FILE="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --timeout-ms) TIMEOUT_MS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [[ -z "$MODE" || -z "$PROMPT_FILE" ]]; then
  echo "Missing required --mode or --prompt-file" >&2
  usage >&2
  exit 1
fi

case "$MODE" in
  plan|review|advice) ;;
  *) echo "Invalid --mode: $MODE (expected plan, review, or advice)" >&2; exit 1 ;;
esac

case "$MODEL" in
  opus|sonnet|fable) ;;
  *) echo "Invalid --model: $MODEL (expected opus, sonnet, or fable)" >&2; exit 1 ;;
esac

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

if ! WORKSPACE="$(cd "$WORKSPACE" && pwd)"; then
  echo "Invalid workspace: $WORKSPACE" >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found. Install Claude Code first." >&2
  exit 127
fi

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
ARTIFACT_DIR="/tmp/consult-claude-${RUN_ID}"
mkdir -p "$ARTIFACT_DIR"

PROMPT_BODY="$(cat "$PROMPT_FILE")"

MODE_INSTRUCTION=""
case "$MODE" in
  plan)
    MODE_INSTRUCTION="Mode: PLAN REVIEW. Critique the proposed approach(es). Compare trade-offs. Do not rewrite from scratch unless a fatal flaw exists. End with a clear recommendation."
    ;;
  review)
    MODE_INSTRUCTION="Mode: REVIEW. Find issues by severity (critical/major/minor). Be specific with file paths and line references when possible. Do not propose drive-by refactors."
    ;;
  advice)
    MODE_INSTRUCTION="Mode: ADVICE. Answer the open question directly. Prefer one strong recommendation over a menu of options. State assumptions and risks."
    ;;
esac

SYSTEM_APPEND="You are an external advisor consulted by another AI agent (Grok Build). ${MODE_INSTRUCTION}

RULES:
- READ-ONLY: Do not modify any files. Do not use Edit or Write tools.
- The implementing agent is Grok; your output is advice only.
- Be concise and actionable.
- If context is insufficient, say what is missing instead of guessing.
${REASON:+Consult reason: ${REASON}}"

# Snapshot workspace state (best-effort) — use full diff, not porcelain lines
if git -C "$WORKSPACE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  {
    git -C "$WORKSPACE" diff HEAD
    git -C "$WORKSPACE" diff --cached HEAD
    git -C "$WORKSPACE" ls-files --others --exclude-standard
  } > "${ARTIFACT_DIR}/pre-workspace.snapshot" 2>/dev/null || true
else
  : > "${ARTIFACT_DIR}/pre-workspace.snapshot"
fi

COMBINED_PROMPT="${MODE_INSTRUCTION}

${PROMPT_BODY}"

run_with_timeout() {
  local secs="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  else
    perl -e 'alarm shift; exec @ARGV' "$secs" "$@"
  fi
}

# Run Claude Code read-only (allow-list only — Bash can bypass Edit/Write blocks)
TIMEOUT_SEC=$((TIMEOUT_MS / 1000))
if ! run_with_timeout "$TIMEOUT_SEC" claude -p \
  --model "$MODEL" \
  --add-dir "$WORKSPACE" \
  --allowed-tools "Read,Grep,Glob" \
  --output-format json \
  --append-system-prompt "$SYSTEM_APPEND" \
  "$COMBINED_PROMPT" \
  > "${ARTIFACT_DIR}/result.json"
then
  EXIT=$?
  if [[ $EXIT -eq 124 ]]; then
    echo "claude -p timed out after ${TIMEOUT_SEC}s (mode=${MODE}, model=${MODEL})" >&2
  else
    echo "claude -p failed (mode=${MODE}, model=${MODEL}, exit=${EXIT})" >&2
  fi
  exit 1
fi

# Extract human-readable response; fail on API errors
python3 - "${ARTIFACT_DIR}/result.json" "${ARTIFACT_DIR}/response.txt" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
if data.get("is_error"):
    msg = data.get("result") or data.get("api_error_status") or "unknown Claude error"
    print(f"Claude returned is_error: {msg}", file=sys.stderr)
    sys.exit(1)
text = data.get("result") or data.get("content") or json.dumps(data, indent=2)
with open(sys.argv[2], "w") as out:
    out.write(text if isinstance(text, str) else json.dumps(text, indent=2))
PY

# Post-flight: detect unexpected file changes via full diff snapshot
if git -C "$WORKSPACE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  {
    git -C "$WORKSPACE" diff HEAD
    git -C "$WORKSPACE" diff --cached HEAD
    git -C "$WORKSPACE" ls-files --others --exclude-standard
  } > "${ARTIFACT_DIR}/post-workspace.snapshot" 2>/dev/null || true
  if ! diff -q "${ARTIFACT_DIR}/pre-workspace.snapshot" "${ARTIFACT_DIR}/post-workspace.snapshot" >/dev/null 2>&1; then
    echo "WORKSPACE_CHANGED_DURING_CONSULT" > "${ARTIFACT_DIR}/files-changed.txt"
    diff -u "${ARTIFACT_DIR}/pre-workspace.snapshot" "${ARTIFACT_DIR}/post-workspace.snapshot" \
      >> "${ARTIFACT_DIR}/files-changed.txt" 2>/dev/null || true
  else
    : > "${ARTIFACT_DIR}/files-changed.txt"
  fi
else
  : > "${ARTIFACT_DIR}/post-workspace.snapshot"
  : > "${ARTIFACT_DIR}/files-changed.txt"
fi

# Emit summary JSON for orchestrator (stdout)
python3 - "${ARTIFACT_DIR}" "$MODE" "$MODEL" "$REASON" <<'PY'
import json, pathlib, sys
art = pathlib.Path(sys.argv[1])
mode, model, reason = sys.argv[2], sys.argv[3], sys.argv[4]
result = {}
rp = art / "result.json"
if rp.exists():
    result = json.loads(rp.read_text())
summary = {
    "ok": not result.get("is_error", False),
    "is_error": result.get("is_error", False),
    "mode": mode,
    "model_alias": model,
    "reason": reason,
    "artifact_dir": str(art),
    "response_file": str(art / "response.txt"),
    "files_changed_file": str(art / "files-changed.txt"),
    "response": (art / "response.txt").read_text(),
    "files_changed": (art / "files-changed.txt").read_text().strip().splitlines(),
    "model_usage": result.get("modelUsage"),
    "total_cost_usd": result.get("total_cost_usd"),
    "duration_ms": result.get("duration_ms"),
}
print(json.dumps(summary, indent=2))
PY