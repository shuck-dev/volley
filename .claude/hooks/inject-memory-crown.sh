#!/usr/bin/env bash
# SessionStart hook: injects the memory-forest crown (five trunk roots, slug + gist).
# The crown is the boot reading list: which trunk to enter depends on the session's focus.
# Fails open: generator error or non-zero exit emits nothing and exits 0.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATOR="${SCRIPT_DIR}/../../scripts/memory/generate-roots.sh"

[ -x "$GENERATOR" ] || exit 0

crown="$(bash "$GENERATOR" 2>/dev/null)" || exit 0
[ -z "$crown" ] && exit 0

note="Memory-forest crown (five trunk roots; enter the matching trunk before branching into leaves):

${crown}

Read the trunk file for whichever tree is relevant to today's session before touching its leaves."

python3 - "$note" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
