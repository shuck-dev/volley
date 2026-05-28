#!/usr/bin/env bash
# Posts a swarm reviewer's line-anchored findings on a PR; applies no label.
# Usage: post-review.sh <pr> <verdict-json with verdict approve|block and items[]>.

set -euo pipefail

die() {
	printf 'post-review: %s\n' "$*" >&2
	exit 1
}

if [[ $# -ne 2 ]]; then
	die "usage: $0 <pr-number> <verdict-json-file>"
fi

pr="$1"
verdict_file="$2"

[[ "$pr" =~ ^[0-9]+$ ]] || die "pr must be a number, got: $pr"
[[ -r "$verdict_file" ]] || die "verdict file not readable: $verdict_file"

command -v gh >/dev/null || die "gh CLI is required"
command -v jq >/dev/null || die "jq is required"

verdict=$(jq -r '.verdict // empty' "$verdict_file")

case "$verdict" in
	approve | block) ;;
	"") die "verdict field is required (approve or block)" ;;
	*) die "invalid verdict: $verdict (expected approve or block)" ;;
esac

if [[ "$verdict" == "approve" ]]; then
	printf 'approve: nothing posted; report the verdict to the organiser.\n'
	exit 0
fi

# Block: post the line-anchored findings on a COMMENT review with an empty body.
items_count=$(jq '(.items // []) | length' "$verdict_file")
[[ "$items_count" -gt 0 ]] || die "items is required and non-empty when verdict is block"

missing=$(jq -r '[(.items // [])[] | select((.path // "") == "" or (.line // null) == null)] | length' "$verdict_file")
[[ "$missing" == "0" ]] || die "every item must carry path and line (got $missing malformed)"

default_commenter=$(jq -r '.commenter // ""' "$verdict_file")
missing_commenter=$(
	jq -r --arg default "$default_commenter" \
		'[(.items // [])[] | select(((.commenter // $default) | length) == 0)] | length' \
		"$verdict_file"
)
[[ "$missing_commenter" == "0" ]] \
	|| die "every item needs a commenter (set top-level .commenter or .items[].commenter; got $missing_commenter missing)"

repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
payload=$(
	jq -n \
		--arg default_commenter "$default_commenter" \
		--slurpfile verdict "$verdict_file" \
		'{
			event: "COMMENT",
			body: "",
			comments: (
				$verdict[0].items | map({
					path,
					line,
					side: "RIGHT",
					body: ("**" + (.commenter // $default_commenter) + "**\n\n" + .body)
				})
			)
		}'
)

printf '%s' "$payload" \
	| gh api "repos/${repo}/pulls/${pr}/reviews" --method POST --input - \
		--jq '"posted findings: \(.html_url)"'

printf 'block: findings posted; report the block to the organiser for the synthesis review.\n'
