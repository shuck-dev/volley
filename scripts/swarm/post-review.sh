#!/usr/bin/env bash
# Posts a swarm reviewer-agent verdict on a pull request.
#
# Usage:
#   scripts/swarm/post-review.sh <pr-number> <verdict-json-file>
#
# Verdict JSON shape:
#   {
#     "verdict": "zaphod-approved" | "zaphod-blocked",
#     "summary": "one-sentence overall finding",
#     "items": [                           # required when blocked
#       {"path": "<file>", "line": <N>, "body": "<concern and fix>"}
#     ]
#   }
#
# Behaviour:
# - zaphod-approved: applies the label; posts nothing. Clean reviews do not
#   clutter the PR.
# - zaphod-blocked: posts a GitHub pull-request review with event=COMMENT
#   (GitHub rejects REQUEST_CHANGES on self-authored PRs), summary as the
#   review body, and each item as a line-anchored review comment on its
#   path and line. Then applies zaphod-blocked.
#
# The script always pipes JSON via stdin to `gh api`, never builds the
# payload by interpolating strings into a shell command, so reviewer
# comment text cannot escape into the shell.

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
summary=$(jq -r '.summary // ""' "$verdict_file")

case "$verdict" in
	zaphod-approved | zaphod-blocked) ;;
	"") die "verdict field is required (zaphod-approved or zaphod-blocked)" ;;
	*) die "invalid verdict: $verdict (expected zaphod-approved or zaphod-blocked)" ;;
esac

if [[ "$verdict" == "zaphod-blocked" ]]; then
	[[ -n "$summary" ]] || die "summary is required when verdict is zaphod-blocked"

	items_count=$(jq '(.items // []) | length' "$verdict_file")
	[[ "$items_count" -gt 0 ]] || die "items is required and non-empty when verdict is zaphod-blocked"

	missing=$(jq -r '[(.items // [])[] | select((.path // "") == "" or (.line // null) == null)] | length' "$verdict_file")
	[[ "$missing" == "0" ]] || die "every item must carry path and line (got $missing malformed)"

	repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
	payload=$(
		jq -n \
			--arg summary "$summary" \
			--slurpfile verdict "$verdict_file" \
			'{
				event: "COMMENT",
				body: $summary,
				comments: ($verdict[0].items | map({path, line, side: "RIGHT", body}))
			}'
	)

	printf '%s' "$payload" \
		| gh api "repos/${repo}/pulls/${pr}/reviews" --method POST --input - \
			--jq '"posted review: \(.html_url)"'
fi

gh pr edit "$pr" --add-label "$verdict" >/dev/null
printf 'applied label: %s\n' "$verdict"
