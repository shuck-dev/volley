#!/usr/bin/env bash
# Stop hook: if the just-finished assistant turn references a PR but ran no live
# PR-state read in that same turn, block once to force a hydrate before the
# claim reaches the user. Fails open: any error or ambiguity exits 0 (no block).
set -uo pipefail

input="$(cat)"

# Loop guard: if this turn was already blocked once, let it through.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[ "$active" = "true" ] && exit 0

tp="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")"
[ -z "$tp" ] && exit 0
[ -f "$tp" ] || exit 0

verdict="$(python3 - "$tp" <<'PY' 2>/dev/null || true
import sys, json, re

path = sys.argv[1]
try:
    raw = open(path, encoding="utf-8", errors="replace").read().splitlines()
except Exception:
    print("0"); sys.exit(0)

records = []
for line in raw:
    line = line.strip()
    if not line:
        continue
    try:
        records.append(json.loads(line))
    except Exception:
        pass

def is_human_prompt(rec):
    # A human prompt is a user-type message whose content is plain text,
    # not a tool_result echo (those are also role user).
    if rec.get("type") != "user":
        return False
    msg = rec.get("message", rec)
    content = msg.get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                return True
        return False
    return False

last_human = -1
for i, r in enumerate(records):
    if is_human_prompt(r):
        last_human = i

turn = records[last_human + 1:] if last_human >= 0 else records

assistant_text = []
tool_inputs = []
for r in turn:
    msg = r.get("message", r)
    role = msg.get("role") or r.get("type")
    content = msg.get("content")
    if isinstance(content, str):
        if role == "assistant":
            assistant_text.append(content)
    elif isinstance(content, list):
        for b in content:
            if not isinstance(b, dict):
                continue
            if b.get("type") == "text" and role == "assistant":
                assistant_text.append(b.get("text", ""))
            elif b.get("type") == "tool_use":
                tool_inputs.append(json.dumps(b.get("input", {})))

text = "\n".join(assistant_text)
cmds = "\n".join(tool_inputs)

mentions_pr = re.search(r"#\d+|\bPRs?\b|pull request", text, re.I) is not None

# Only meaningful when the text asserts a PR's state, not just names a PR.
state_claim = re.search(
    r"\b("
    r"merged|is open|is closed|reopened|blocked|approved|approval|"
    r"passing|passed|failing|failed|mergeable|queued|landed|"
    r"ready to merge|auto-?merge|all checks|checks? (pass|green|red|fail)|"
    r"review (passed|verdict|blocked|approved)|green|red"
    r")\b",
    text, re.I) is not None

# Only a live READ this turn grounds a state claim; the command result is the
# ground truth. Write verbs (create, merge, close, edit, ready, comment, review,
# reopen) change a PR but do not read its current state, so they do NOT ground a
# claim like "is mergeable" or "approved". Reading verbs only.
touched = re.search(
    r"gh pr (view|list|status|checks|diff)"
    r"|gh api[^\n]*(/pulls|/issues)",
    cmds, re.I) is not None

print("1" if (mentions_pr and state_claim and not touched) else "0")
PY
)"

if [ "$verdict" = "1" ]; then
  printf '%s\n' '{"decision":"block","reason":"state-check: this response referenced a PR or challenge state without a live gh read this turn. Run the gh read now (gh pr view <n> --json state,mergeable,reviewDecision or gh pr checks <n>), correct any claim that does not match, then stop."}'
fi

exit 0
