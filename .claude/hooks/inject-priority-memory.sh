#!/usr/bin/env bash
# SessionStart hook: inject the bodies of priority-flagged memories into context.
# A memory is priority when its frontmatter metadata carries `priority: true`.
# Fails open: any error prints nothing and exits 0 (no injection, no block).
set -uo pipefail

MEM_DIR="/home/josh/.claude/projects/-home-josh-gamedev-volley/memory"
[ -d "$MEM_DIR" ] || exit 0

out="$(
  python3 - "$MEM_DIR" <<'PY' 2>/dev/null || true
import sys, os, glob

mem_dir = sys.argv[1]
blocks = []
for path in sorted(glob.glob(os.path.join(mem_dir, "*.md"))):
    if os.path.basename(path) == "MEMORY.md":
        continue
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except Exception:
        continue
    if not text.startswith("---"):
        continue
    end = text.find("---", 3)
    if end == -1:
        continue
    front = text[3:end]
    # priority flag lives in frontmatter (metadata.priority: true or top-level priority: true)
    is_priority = any(
        line.strip().replace(" ", "").lower() == "priority:true"
        for line in front.splitlines()
    )
    if not is_priority:
        continue
    body = text[end + 3:].strip()
    name = os.path.basename(path)[:-3]
    blocks.append(f"### {name}\n{body}")

if blocks:
    print("Priority memories (always loaded; these are load-bearing rules):\n")
    print("\n\n".join(blocks))
PY
)"

[ -z "$out" ] && exit 0

# SessionStart hooks inject context via additionalContext in JSON output.
python3 - "$out" <<'PY' 2>/dev/null || true
import sys, json
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
exit 0
