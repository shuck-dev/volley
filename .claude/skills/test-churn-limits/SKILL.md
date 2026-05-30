---
name: test-churn-limits
description: Hard caps for implementer minions to stop grinding on a failing test. Read at brief-open before writing the first line of code.
---

# Test-churn limits

An implementer that fails to make a test pass after a few attempts escalates with the failing evidence rather than continuing to thrash. Grinding on the same shape rarely converges, and the parent thread waits on a minion that is no longer making progress.

## Hard limits per dispatch

- **Three genuinely different fix attempts per failing test.** A different attempt changes the approach (different file, different assertion shape, different setup), not the value of a number, not a one-character variation. After three, escalate.
- **Tool-call ceiling: 80 per dispatch.** Successful implementer runs sit in the 30–60 range. Past 80 the work is churning; the brief, the test, or the diff is wrong, and the dispatcher needs to see it.
- **Per-test wall-clock soft-cap: 5 minutes.** If a test stays red after five minutes of attempts, report the failing state and stop.

A "genuinely different attempt" is one where the hypothesis about why the test fails changes. Tweaking a literal, retrying after a small rename, or rephrasing the same assertion does not count.

## Escalation report shape

When you hit any limit, your final report names:

- The failing test (file:line, assertion that fails).
- The last three attempts: what changed, why it didn't work.
- Best guess: is the test wrong, the diff wrong, or the brief asking for something incoherent.
- What you'd try next if you had more headroom.

The dispatcher decides whether to rewrite the brief, rewrite the test, or absorb the diff and continue. That decision is faster than another half-hour of attempts you couldn't make work.

## What this rule is not

It is not permission to ship a red test. It is permission to **stop**, not permission to ignore. The escalation report is the deliverable when the limits hit; an implementer that pushes a draft with failing tests AND no escalation report has failed the dispatch.
