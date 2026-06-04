#!/usr/bin/env bash
# Pick a minion codename: choose a theme, then a name from it not already used
# this session. Used names are read from ai/scratchpads/agent-codenames.tsv
# (column 2). Prints one name to stdout.
#
# Usage:
#   pick-codename.sh              # random theme, random unused name
#   pick-codename.sh outer-wilds  # named theme, random unused name from it
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pool_dir="$here/codenames"
used_file="$here/../../ai/scratchpads/agent-codenames.tsv"

# Names already handed out this session (TSV column 2), empty if no log yet.
used=""
if [[ -f "$used_file" ]]; then
	used="$(cut -f2 "$used_file" 2>/dev/null || true)"
fi

# Resolve the theme list: the named theme, or all themes shuffled so an
# exhausted first pick falls through to another.
themes=()
if [[ $# -ge 1 ]]; then
	[[ -f "$pool_dir/$1.txt" ]] || { echo "no such theme: $1" >&2; exit 1; }
	themes=("$1")
else
	while IFS= read -r f; do themes+=("$(basename "$f" .txt)"); done \
		< <(find "$pool_dir" -name '*.txt' | sort -R)
fi

for theme in "${themes[@]}"; do
	# Names in this theme minus the ones already used, then one at random.
	pick="$(grep -vxF -f <(printf '%s\n' "$used") "$pool_dir/$theme.txt" \
		| grep -v '^[[:space:]]*$' | sort -R | head -n1 || true)"
	if [[ -n "$pick" ]]; then
		echo "$pick"
		exit 0
	fi
done

echo "every codename in the requested pool is already used this session" >&2
exit 1
