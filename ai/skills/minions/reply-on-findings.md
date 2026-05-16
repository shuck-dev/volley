---
name: reply-on-findings
description: Reply on a PR finding (reviewer comment or Josh comment) after the fix lands. The shape every fold-and-reply minion uses, so the dispatch brief can point here instead of inlining the gh api command every time.
---

# Replying on findings

Every inline finding on a PR (from a reviewer specialist or from Josh) gets a reply once the fix lands. Silent pushes leave the thread open and the next person reading the PR cannot tell whether the finding was addressed, deferred, or refused.

## When to reply

- Fix landed in a commit on the same PR: reply with the SHA.
- Finding deferred to a follow-up issue: reply with the issue number.
- Finding refused (out of scope, intentional, not load-bearing): reply with the reason in one sentence.

If you are the agent who wrote the fix, you reply. If Gru is folding multiple finds from one fan-out, Gru replies under the `**Gru**` byline.

## The command

```
gh api -X POST repos/shuck-dev/volley/pulls/<pr-number>/comments/<comment-id>/replies \
  -f body='**<Codename>**: fixed in <sha-7>; <one short clause naming what changed>.'
```

`<comment-id>` is the inline comment id (returned by `gh api repos/.../pulls/<n>/comments`), not the review id. Replies attach to the threaded discussion under the original comment.

## Body shape

- Lead with the codename in bold (`**Gru**`, `**Penny**`, `**Otis**`). One word, no role suffix.
- Name the SHA in 7-char short form: `fixed in af47cd4`.
- One clause after the SHA naming what the fix actually did. Not "addressed your feedback"; name the change.
- Under 30 words. Reviewers wrote the long analysis; you write the receipt.
- No em dashes anywhere. Commas, semicolons, parentheses.

Examples:

> **Penny**: fixed in c0ee6fd; blank-line phases inside configure / mount / press-area / on-press.

> **Otis** (devils-advocate): re-verified at HEAD, fix holds; ASCENDING now derives target from `_lane_foot_y` minus current half_height, foot invariant preserved across in-pose resize.

> **Gru**: deferred to SH-409 (paddle-movement spike); dormant today because court owns both nodes.

> **Gru**: refused; the orphan is intentional, the refusal-animation listener lands in its own ticket.

## Where NOT to post

- No PR Review body. Inline replies only. See `feedback_reviews_never_main_thread`.
- No new top-level PR comment ("addressed all the comments, please re-review"). Each finding gets its own threaded reply.
- No comment on a stale/superseded commit; reply on the original comment, even if the commit it cites is no longer HEAD.

## Bulk replies

If one commit folds N findings, fire N reply calls (one per comment id), not one umbrella message. Each thread closes independently. Bash supports a tight loop:

```
for id in 3252953026 3252954847; do
  gh api -X POST repos/shuck-dev/volley/pulls/675/comments/$id/replies \
    -f body="**Penny**: fixed in c0ee6fd; blank-line phases between logical sections."
done
```

## After every reply

No re-fan label flip needed for mechanical fold-ins. Per `feedback_re_fan_only_on_scope_change`, only material scope changes earn a fresh reviewer pass. If a reviewer needs to verify the fix, leave them a reply naming the SHA and let Josh decide whether to re-fan with `zaphod-requested`.
