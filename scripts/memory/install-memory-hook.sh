#!/usr/bin/env bash
# Installs the graph-edge lint as a pre-commit hook in the memory repo.
# Run once after cloning or whenever the hook needs reinstalling.
#
# The memory repo is expected at:
#   ~/.claude/projects/-home-josh-gamedev-volley/memory
#
# The lint script is expected at:
#   <this-script's-repo-root>/scripts/memory/lint-graph-edges.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT_SCRIPT="$SCRIPT_DIR/lint-graph-edges.sh"

MEMORY_DIR="$HOME/.claude/projects/-home-josh-gamedev-volley/memory"
HOOK_PATH="$MEMORY_DIR/.git/hooks/pre-commit"

if [[ ! -d "$MEMORY_DIR/.git" ]]; then
    echo "install-memory-hook: memory repo not found at $MEMORY_DIR" >&2
    exit 1
fi

if [[ ! -f "$LINT_SCRIPT" ]]; then
    echo "install-memory-hook: lint script not found at $LINT_SCRIPT" >&2
    exit 1
fi

cat > "$HOOK_PATH" <<EOF
#!/usr/bin/env bash
# Graph-edge lint: validates parent: frontmatter edges in the memory corpus.
# Installed by scripts/memory/install-memory-hook.sh
set -euo pipefail
MEMORY_REPO="\$(cd "\$(dirname "\$0")/../.." && pwd)"
exec "$LINT_SCRIPT" "\$MEMORY_REPO"
EOF

chmod +x "$HOOK_PATH"
echo "install-memory-hook: hook installed at $HOOK_PATH"
